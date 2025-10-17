#!/usr/bin/env bash
set -euo pipefail

# Config
REGION_FILTER="${REGION_FILTER:-us}" # e.g., "us" or "us,ca" or "country:us" or "city:New York"
TOP_N="${TOP_N:-2}"                  # number of candidates to keep (we will pick best, and keep top N as fallback)
WG_IFACE="${WG_IFACE:-vpn0}"
: "${PRIVATE_KEY_FILE:?PRIVATE_KEY_FILE must be set (path to your SOPS-encrypted WireGuard key)}"
: "${VPN_ADDRESS:?VPN_ADDRESS must be set (your Mullvad-assigned IP address)}"
VPN_DNS="${VPN_DNS:-}" # comma-separated DNS servers (optional)
VPN_ALLOWED_IPS="${VPN_ALLOWED_IPS:-0.0.0.0/0, ::/0}" # IP ranges to route through VPN
WG_CONF_PATH="${WG_CONF_PATH:-/etc/wireguard/${WG_IFACE}.conf}"
MULLVAD_API="${MULLVAD_API:-https://api.mullvad.net/www/relays/wireguard/}"
PING_TIMEOUT="${PING_TIMEOUT:-1}"                # seconds for ping
TCP_TIMEOUT="${TCP_TIMEOUT:-1}"                  # seconds for tcp connect test
MEASURE_METHOD="${MEASURE_METHOD:-tcp}"          # tcp or ping
SWITCH_THRESHOLD_MS="${SWITCH_THRESHOLD_MS:-15}" # only switch if new server is this many ms faster

# helpers
log() { echo "$(date -Iseconds) [mullvad-select] $*"; }

# Ensure needed binaries
for bin in curl jq wg wg-quick ip; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    log "ERROR: missing required binary: $bin"
    exit 2
  fi
done

# Read private key
if [ ! -r "$PRIVATE_KEY_FILE" ]; then
  log "ERROR: private key file $PRIVATE_KEY_FILE not found or unreadable"
  exit 2
fi

# Self-healing: Check if VPN interface exists but connection is dead
force_reselection=false
if ip link show dev "$WG_IFACE" >/dev/null 2>&1; then
  # Check if we have a valid handshake (connection is working)
  latest_handshake=$(wg show "$WG_IFACE" latest-handshakes | awk '{print $2}')
  current_time=$(date +%s)

  if [ -n "$latest_handshake" ] && [ "$latest_handshake" != "0" ]; then
    time_since_handshake=$((current_time - latest_handshake))
    # Allow ~3 minutes without handshake (rekey interval ~2min + slack)
    if [ "$time_since_handshake" -gt 180 ]; then
      log "VPN interface exists but no handshake in ${time_since_handshake}s - connection is dead, forcing reselection"
      force_reselection=true
      wg-quick down "$WG_IFACE" || true
    fi
  else
    # No handshake at all - try to bring it up with current config
    if [ -f "$WG_CONF_PATH" ]; then
      log "VPN interface exists but no handshake - attempting to reconnect with existing config"
      wg-quick down "$WG_IFACE" || true
      if wg-quick up "$WG_IFACE" 2>/dev/null; then
        log "Successfully reconnected VPN"
        exit 0
      else
        log "Failed to reconnect with existing config, will select new server"
        force_reselection=true
      fi
    else
      log "VPN interface exists but no config file found, will create new config"
      wg-quick down "$WG_IFACE" || true
      force_reselection=true
    fi
  fi
fi

# Fetch Mullvad relays JSON (cache locally for a short time to avoid rates)
# systemd CacheDirectory creates /var/cache/mullvad
# Cache timeout aligns with systemd timer (10 minutes)
CACHE_DIR="${CACHE_DIRECTORY:-/var/cache/mullvad}"
CACHE_TIMEOUT_MINS="${CACHE_TIMEOUT_MINS:-10}"
TMP_JSON="$CACHE_DIR/relays.json"
mkdir -p "$CACHE_DIR"
if [ -f "$TMP_JSON" ] && [ "$(find "$TMP_JSON" -mmin -"$CACHE_TIMEOUT_MINS" -print)" ]; then
  RELAYS_JSON="$(cat "$TMP_JSON")"
else
  RELAYS_JSON="$(curl -fsS "$MULLVAD_API")" || {
    log "ERROR: failed to fetch Mullvad API"
    exit 3
  }
  echo "$RELAYS_JSON" >"$TMP_JSON"
fi

# Filter relays by REGION_FILTER
# REGION_FILTER can be: "us", "us,ca", "city:New York", etc.
filter_relays() {
  local f="$1"
  if echo "$f" | grep -q '^city:'; then
    city="${f#city:}"
    echo "$RELAYS_JSON" | jq -c --arg city "$city" '.[] | select(.city_name == $city and .active == true)'
  else
    # treat as comma-separated country codes
    IFS=',' read -ra C <<<"$f"
    for c in "${C[@]}"; do
      echo "$RELAYS_JSON" | jq -c --arg c "$c" '.[] | select(.country_code == $c and .active == true)'
    done
  fi
}

RELAYS="$(filter_relays "$REGION_FILTER")"
if [ -z "$RELAYS" ]; then
  log "No relays matched region filter '$REGION_FILTER' — falling back to top active relays"
  RELAYS="$(echo "$RELAYS_JSON" | jq -c '.[] | select(.active==true and .owned==true)')"
fi

# Measure latency function
measure_latency() {
  local ip="$1"
  if [ "$MEASURE_METHOD" = "ping" ]; then
    # Use ping; may require root capabilities for raw sockets but usually allowed
    if ping -c 1 -W "$PING_TIMEOUT" "$ip" >/dev/null 2>&1; then
      # extract RTT
      rtt=$(ping -c 1 -W "$PING_TIMEOUT" "$ip" | awk -F'/' 'END{print $5}')
      echo "${rtt:-999}"
    else
      echo "9999"
    fi
  else
    # TCP connect measurement: try connecting to 51820 (WireGuard) with timeout via bash
    start=$(date +%s%3N)
    (echo >/dev/tcp/"$ip"/51820) >/dev/null 2>&1 && success=0 || success=1
    stop=$(date +%s%3N)
    if [ "$success" -eq 0 ]; then
      latency=$((stop - start))
      echo "$latency"
    else
      echo "9999"
    fi
  fi
}

# Build candidate list with measured latency
candidates_tmp="$(mktemp)"
pids=()
echo "$RELAYS" | while IFS= read -r line; do
  ip=$(echo "$line" | jq -r '.ipv4_addr_in // .ipv4_addr')
  host=$(echo "$line" | jq -r '.hostname')
  pub=$(echo "$line" | jq -r '.pubkey')
  city=$(echo "$line" | jq -r '.city_name')
  country=$(echo "$line" | jq -r '.country_code')
  if [ -z "$ip" ] || [ "$ip" = "null" ]; then
    continue
  fi
  # Each background job writes to its own temp file to avoid race conditions
  (
    latency=$(measure_latency "$ip")
    temp_out="$(mktemp)"
    printf '%s\t%s\t%s\t%s\t%s\n' "$latency" "$ip" "$pub" "$host" "$city,$country" >"$temp_out"
    cat "$temp_out" >>"$candidates_tmp"
    rm -f "$temp_out"
  ) &
  pids+=($!)
done
# Wait for all measurement jobs to complete
for pid in "${pids[@]}"; do
  wait "$pid"
done

# sort and pick top N
mapfile -t sorted < <(sort -n "$candidates_tmp")
rm -f "$candidates_tmp"

if [ ${#sorted[@]} -eq 0 ]; then
  log "No candidate servers measured successfully"
  exit 4
fi

# Pick top N
selected=()
i=0
for row in "${sorted[@]}"; do
  if [ $i -ge "$TOP_N" ]; then break; fi
  IFS=$'\t' read -r latency ip pub host loc <<<"$row"
  selected+=("$latency|$ip|$pub|$host|$loc")
  i=$((i + 1))
done

log "Selected top $TOP_N candidates:"
for s in "${selected[@]}"; do
  log "  $s"
done

# Build wg-quick conf for the active (best) server (first in list)
best="${selected[0]}"
best_latency="${best%%|*}"
rest="${best#*|}"
best_ip="${rest%%|*}"
rest="${rest#*|}"
best_pub="${rest%%|*}"
rest="${rest#*|}"
best_host="${rest%%|*}"

log "Best server candidate: $best_host ($best_ip) latency ${best_latency}ms"

# Check if we're already connected and if so, should we switch?
current_endpoint=""
current_pubkey=""
current_latency=""
if ! $force_reselection && ip link show dev "$WG_IFACE" >/dev/null 2>&1; then
  # Get current peer info
  current_pubkey=$(wg show "$WG_IFACE" peers | head -1)
  current_endpoint=$(wg show "$WG_IFACE" endpoints | awk '{print $2}' | cut -d: -f1)

  if [ -n "$current_endpoint" ]; then
    # Measure current server's latency
    current_latency=$(measure_latency "$current_endpoint")
    log "Currently connected to endpoint $current_endpoint (pubkey: ${current_pubkey:0:20}...) with latency ${current_latency}ms"

    # Check if we should switch
    # Convert latencies to integers for comparison (remove decimal points)
    best_latency_int=${best_latency%%.*}
    current_latency_int=${current_latency%%.*}
    latency_improvement=$((current_latency_int - best_latency_int))

    if [ "$current_pubkey" = "$best_pub" ]; then
      log "Already connected to best server, no change needed"
      exit 0
    elif [ "$latency_improvement" -lt "$SWITCH_THRESHOLD_MS" ]; then
      log "New server only ${latency_improvement}ms faster (threshold: ${SWITCH_THRESHOLD_MS}ms), staying with current server"
      exit 0
    else
      log "New server is ${latency_improvement}ms faster (threshold: ${SWITCH_THRESHOLD_MS}ms), switching servers"
    fi
  fi
elif $force_reselection; then
  log "Force reselection enabled - will select new server"
fi

log "Configuring VPN to use $best_host ($best_ip) latency ${best_latency}ms"

# Create wg-quick file. We will route 0.0.0.0/0 and ::/0, use PersistentKeepalive on selected peer
# Build DNS line if VPN_DNS is set
dns_line=""
if [ -n "$VPN_DNS" ]; then
  # Convert comma-separated to space-separated for wg-quick
  dns_servers=$(echo "$VPN_DNS" | tr ',' ' ')
  dns_line="DNS = $dns_servers"
fi

cat >"$WG_CONF_PATH" <<EOF
[Interface]
PrivateKey = $(cat "$PRIVATE_KEY_FILE")
Address = ${VPN_ADDRESS}
${dns_line}
ListenPort = 51820

[Peer]
PublicKey = ${best_pub}
AllowedIPs = ${VPN_ALLOWED_IPS}
Endpoint = ${best_ip}:51820
PersistentKeepalive = 25
EOF

chmod 600 "$WG_CONF_PATH"

# Bring wg-quick up (restart if already up)
if ip link show dev "$WG_IFACE" >/dev/null 2>&1; then
  log "Interface $WG_IFACE exists, restarting"
  wg-quick down "$WG_IFACE" || true
fi

wg-quick up "$WG_IFACE"
log "WireGuard interface $WG_IFACE is up and routing through $best_host"

exit 0
