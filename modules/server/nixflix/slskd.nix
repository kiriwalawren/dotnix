{
  flake.modules.nixos.homelab =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      vpnNamespace = "slsk";
    in
    {
      sops.secrets = {
        "wireguard-confs/protonvpn-slskd" = { };
        "slskd/username" = { };
        "slskd/password" = { };
        "slskd/api-key" = { };
      };

      vpnNamespaces.${vpnNamespace} = {
        enable = config.nixflix.slskd.enable;
        wireguardConfigFile = config.sops.secrets."wireguard-confs/protonvpn-slskd".path;
        inherit (config.vpnNamespaces.wg) accessibleFrom;

        # Must differ from the "wg" namespace's addresses (both default to
        # 192.168.15.1/192.168.15.5 in VPN-Confinement).
        namespaceAddress = "192.168.16.1";
        namespaceAddressIPv6 = "fd93:9701:1d00::1:2";
        bridgeAddress = "192.168.16.5";
        bridgeAddressIPv6 = "fd93:9701:1d00::1:1";
      };

      nixflix.slskd = {
        enable = true;
        # Must differ from the "slskd" service name itself: vpn-confinement
        # generates a systemd unit named after the namespace, which would
        # otherwise collide with systemd.services.slskd.
        vpn.namespace = vpnNamespace;

        username._secret = config.sops.secrets."slskd/username".path;
        password._secret = config.sops.secrets."slskd/password".path;
        apiKey._secret = config.sops.secrets."slskd/api-key".path;

        settings.soulseek = {
          username._secret = config.sops.secrets."slskd/username".path;
          password._secret = config.sops.secrets."slskd/password".path;
        };
      };

      # Override nixpkgs' mkForce false (priority 50); the overlay PATCH is in-memory only.
      services.slskd.settings.remote_configuration = lib.mkOverride 40 true;

      systemd.services.slskd-protonvpn-port-forward =
        lib.mkIf (config.nixflix.vpn.enable && config.nixflix.slskd.enable)
          {
            description = "ProtonVPN port forwarding for slskd";
            after = [
              "${config.systemd.services.slskd.vpnConfinement.vpnNamespace}.service"
              "slskd.service"
            ];
            requires = [
              "${config.systemd.services.slskd.vpnConfinement.vpnNamespace}.service"
              "slskd.service"
            ];
            wantedBy = [ "multi-user.target" ];

            path = [
              pkgs.curl
              pkgs.jq
              pkgs.libnatpmp
              pkgs.iproute2
              pkgs.gawk
            ];

            serviceConfig = {
              Type = "simple";
              Restart = "on-failure";
              RestartSec = "5s";
              ExecStart =
                let
                  ns = config.systemd.services.slskd.vpnConfinement.vpnNamespace;
                  slskdHost = "http://127.0.0.1:${toString config.services.slskd.settings.web.port}";
                  apiKeyFile = config.sops.secrets."slskd/api-key".path;
                in
                pkgs.writeShellScript "slskd-protonvpn-port-forward" ''
                  SLSKD_HOST="${slskdHost}"
                  API_KEY=$(cat ${apiKeyFile})

                  read_current_port() {
                    local response status body
                    response=$(ip netns exec ${ns} curl -s -w '\n%{http_code}' \
                      -H "X-API-Key: $API_KEY" "$SLSKD_HOST/api/v0/options")
                    status=$(echo "$response" | tail -n1)
                    body=$(echo "$response" | sed '$d')

                    if [ "$status" != "200" ]; then
                      echo "Failed to read slskd options (HTTP $status): $body" >&2
                      return 1
                    fi

                    echo "$body" | jq '.soulseek.listenPort'
                  }

                  update_port() {
                    local port response status body
                    port="$1"
                    response=$(ip netns exec ${ns} curl -s -w '\n%{http_code}' \
                      -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
                      --request PATCH --data "{\"soulseek\":{\"listenPort\":$port}}" \
                      "$SLSKD_HOST/api/v0/options")
                    status=$(echo "$response" | tail -n1)
                    body=$(echo "$response" | sed '$d')

                    if [ "$status" != "200" ] && [ "$status" != "204" ]; then
                      echo "Failed to update slskd listen port to $port (HTTP $status): $body" >&2
                      return 1
                    fi

                    echo "Updated slskd listen port to $port (HTTP $status)"
                  }

                  CURRENT_PORT=$(read_current_port)

                  while true; do
                    UDP_OUT=$(ip netns exec ${ns} natpmpc -a 1 0 udp 60 -g 10.2.0.1)
                    ip netns exec ${ns} natpmpc -a 1 0 tcp 60 -g 10.2.0.1

                    PORT=$(echo "$UDP_OUT" | grep "Mapped public port" | awk '{print $4}')

                    if [ -z "$PORT" ]; then
                      echo "Failed to get port, is the tunnel up?"
                      sleep 5
                      continue
                    fi

                    if [ "$PORT" != "$CURRENT_PORT" ]; then
                      echo "Port changed: $CURRENT_PORT -> $PORT, updating slskd..."
                      if update_port "$PORT"; then
                        CURRENT_PORT=$PORT
                      fi
                    fi

                    sleep 5
                  done
                '';
            };
          };
    };
}
