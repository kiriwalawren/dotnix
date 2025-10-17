#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Full "dotnix" bootstrap — one‑shot install with nixos‑anywhere              #
#                                                                             #
# Flow summary                                                                #
# 0. Generate target SSH host key + age recipient (secrets ready day‑0)       #
# 1. Optionally capture hardware‑configuration.nix **before** install         #
# 2. Run nixos‑anywhere streaming the full dotnix flake (build locally)       #
# 3. Optionally rsync dotnix repo to host (no auto‑rebuild)                   #
# 4. Optionally **git add**, commit & push *all* changes in one go            #
# 5. Print next‑steps summary                                                 #
###############################################################################

# Helpers library
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

###############
# User inputs #
###############

target_hostname=""
target_destination=""
target_user=${BOOTSTRAP_USER-$(whoami)}
ssh_port=${BOOTSTRAP_SSH_PORT-22}
ssh_key=${BOOTSTRAP_SSH_KEY-}

nix_src_path="gitrepos" # destination dir on target for rsync

# dotnix paths
git_root=$(git rev-parse --show-toplevel)
nix_secrets_dir=${NIX_SECRETS_DIR:-"${git_root}/../secrets"}
nix_secrets_yaml="${nix_secrets_dir}/secrets.yaml"

################
# Temp staging #
################

temp=$(mktemp -d)
trap 'rm -rf "$temp"' EXIT

#########################
# Convenience functions #
#########################

sync() {
  # $1 = user, $2 = local source tree
  rsync -av --filter=':- .gitignore' -e "ssh -oControlMaster=no -l $1 -oPort=${ssh_port}" "$2" "$1@${target_destination}:${nix_src_path}"
}

help_and_exit() {
  cat <<EOF
Installs *full* dotnix NixOS on a remote machine in one step.

USAGE: $0 -n <hostname> -d <ip-or-domain> -k <ssh_key> [OPTIONS]

ARGS:
  -n <hostname>     Hostname as defined in flake (e.g., media‑hetzner).
  -d <destination>  IP or DNS of the target.
  -k <ssh_key>      Path to private SSH key used for install.

OPTIONS:
  -u <user>         SSH user with sudo (default: $target_user).
  --port <port>     SSH port (default: $ssh_port).
  --debug           Bash xtrace for troubleshooting.
  -h|--help         Show this help.
EOF
  exit 0
}

########################
# CLI argument parsing #
########################

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n)
      shift
      target_hostname=$1
      ;;
    -d)
      shift
      target_destination=$1
      ;;
    -u)
      shift
      target_user=$1
      ;;
    -k)
      shift
      ssh_key=$1
      ;;
    --port)
      shift
      ssh_port=$1
      ;;
    --debug) set -x ;;
    -h | --help) help_and_exit ;;
    *)
      red "Invalid option: $1"
      help_and_exit
      ;;
  esac
  shift
done

if [[ -z $target_hostname || -z $target_destination || -z $ssh_key ]]; then
  red "ERROR: -n, -d and -k are required"
  help_and_exit
fi

##########################################
# SSH command templates (no ControlPath) #
##########################################

ssh_base=(ssh -oControlPath=none -oForwardAgent=yes -oStrictHostKeyChecking=no
  -oUserKnownHostsFile=/dev/null -oPort=$ssh_port -i "$ssh_key")
ssh_cmd=("${ssh_base[@]}" -t "$target_user@$target_destination")
ssh_root_cmd=("${ssh_base[@]}" -t "root@$target_destination")
scp_cmd=(scp -oControlPath=none -oStrictHostKeyChecking=no -oPort=$ssh_port -i "$ssh_key")

#############################################
# 0. Generate host SSH key & age recipient  #
#############################################

blue "[0/5] Generating host SSH key and age recipient"
install -d -m755 "$temp/etc/ssh"
ssh-keygen -t ed25519 -f "$temp/etc/ssh/ssh_host_ed25519_key" -C "$target_user@$target_hostname" -N ""
chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"

host_age_key=$(ssh-to-age <"$temp/etc/ssh/ssh_host_ed25519_key.pub")
if [[ $host_age_key != age1* ]]; then
  red "Failed to convert SSH key to age recipient"
  exit 1
fi
sops_update_age_key hosts "$target_hostname" "$host_age_key"
sops updatekeys -y "$nix_secrets_yaml"

green "Age recipient added; secrets re‑encrypted"

###################################################
# 1. Optional *early* hardware‑configuration grab #
###################################################

if no_or_yes "Capture hardware-configuration.nix before install?"; then
  blue "[1/5] Capturing hardware-configuration.nix (pre‑install)"
  if "${ssh_root_cmd[@]}" command -v nixos-generate-config >/dev/null 2>&1; then
    "${ssh_root_cmd[@]}" "nixos-generate-config --no-filesystems --root /mnt || nixos-generate-config --no-filesystems --root /"
    "${scp_cmd[@]}" root@"$target_destination":/mnt/etc/nixos/hardware-configuration.nix "$git_root/hosts/hardware/$target_hostname.nix" 2>/dev/null ||
      "${scp_cmd[@]}" root@"$target_destination":/etc/nixos/hardware-configuration.nix "$git_root/hosts/hardware/$target_hostname.nix" 2>/dev/null ||
      yellow "Unable to fetch hardware-configuration.nix; continuing"
  else
    yellow "nixos-generate-config not available on target; skipping capture"
  fi
fi

#################################################
# 2. Run nixos-anywhere install (build locally) #
#################################################

blue "[2/5] Running nixos-anywhere (build locally)"

# Clean & pre‑seed known_hosts
sed -i "/$target_hostname/d; /$target_destination/d" ~/.ssh/known_hosts || true
ssh-keyscan -p "$ssh_port" "$target_destination" 2>/dev/null >>~/.ssh/known_hosts || true

(
  cd "$git_root"
  SHELL=/bin/sh nix run github:nix-community/nixos-anywhere -- \
    --ssh-port "$ssh_port" \
    --post-kexec-ssh-port "$ssh_port" \
    --extra-files "$temp" \
    --flake .#"$target_hostname" \
    --target-host root@"$target_destination"
)

#################################################
# 3. Optional repo sync (no rebuild afterwards) #
#################################################

if yes_or_no "Sync the dotnix repo to $target_hostname?"; then
  green "Adding $target_destination to local known_hosts"
  ssh-keyscan -p "$ssh_port" "$target_destination" 2>/dev/null | grep -v '^#' >>~/.ssh/known_hosts || true
  green "Syncing dotnix repository to $target_hostname:$nix_src_path"
  sync "$target_user" "$git_root"
  green "Syncing secrets repository to $target_hostname:$nix_src_path"
  sync "$target_user" "$nix_secrets_dir"
fi

#########################################################
# 4. Optionally git‑add, commit & push all changes      #
#########################################################

if yes_or_no "Stage, commit, and push all changes to Git?"; then
  git -C "$nix_secrets_dir" add -A
  git -C "$nix_secrets_dir" commit -m "bootstrap: $target_hostname initial setup" || true
  git -C "$nix_secrets_dir" push || true

  nix fmt
  nix flake update secrets
  git -C "$git_root" add -A
  git -C "$git_root" commit -m "bootstrap: $target_hostname initial setup" || true
  git -C "$git_root" push || true
fi

########################
# 5. Finished summary  #
########################

green "Success! $target_hostname is now running full dotnix."

echo "\nNext steps:"
echo "  ssh $target_user@$target_destination -p $ssh_port"
echo "  sudo nixos-rebuild switch --flake ~/gitrepos/dotnix#$target_hostname   # update in the future"
