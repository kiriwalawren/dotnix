#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Full "dotnix" bootstrap — one‑shot install with nixos‑anywhere              #
#                                                                             #
# Flow summary                                                                #
# 0. Generate target SSH host key + age recipient (secrets ready day‑0)       #
# 1. Optionally capture hardware‑configuration.nix **before** install         #
# 2. Run nixos‑anywhere streaming the full dotnix flake (build locally)       #
#    Can also do encryption and secure boot
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
enable_secureboot=false

nix_src_path="gitrepos" # destination dir on target for rsync

# dotnix paths
git_root=$(git rev-parse --show-toplevel)
nix_secrets_dir=${NIX_SECRETS_DIR:-"${git_root}/../secrets"}
nix_secrets_yaml="${nix_secrets_dir}/secrets.yaml"
nix_secrets_config="${nix_secrets_dir}/.sops.yaml"

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
  --secureboot      Enable Secure Boot + TPM2 setup (automated phases 2-3).
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
    --secureboot)
      enable_secureboot=true
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

blue "Generating host SSH key and age recipient"
install -d -m755 "$temp/etc/ssh"
ssh-keygen -t ed25519 -f "$temp/etc/ssh/ssh_host_ed25519_key" -C "$target_user@$target_hostname" -N ""
chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"

host_age_key=$(ssh-to-age <"$temp/etc/ssh/ssh_host_ed25519_key.pub")
if [[ $host_age_key != age1* ]]; then
  red "Failed to convert SSH key to age recipient"
  exit 1
fi
sops_update_age_key hosts "$target_hostname" "$host_age_key"
ln -s "$nix_secrets_config" ./.sops.yaml
sops updatekeys -y "$nix_secrets_yaml"
rm ./.sops.yaml
git -C "$nix_secrets_dir" add -A
git -C "$nix_secrets_dir" commit -m "bootstrap: $target_hostname initial setup" || true
git -C "$nix_secrets_dir" push || true
nix flake update secrets

green "Age recipient added; secrets re‑encrypted"

###################################################
# 1. Optional *early* hardware‑configuration grab #
###################################################

if no_or_yes "Capture hardware-configuration.nix before install?"; then
  blue "Capturing hardware-configuration.nix (pre‑install)"
  if "${ssh_root_cmd[@]}" command -v nixos-generate-config >/dev/null 2>&1; then
    "${ssh_root_cmd[@]}" "nixos-generate-config --no-filesystems --root /mnt || nixos-generate-config --no-filesystems --root /"
    "${scp_cmd[@]}" root@"$target_destination":/mnt/etc/nixos/hardware-configuration.nix "$git_root/hosts/$target_hostname/hardware-configuration.nix" 2>/dev/null ||
      "${scp_cmd[@]}" root@"$target_destination":/etc/nixos/hardware-configuration.nix "$git_root/hosts/$target_hostname/hardware-configuration.nix" 2>/dev/null ||
      yellow "Unable to fetch hardware-configuration.nix; continuing"
  else
    yellow "nixos-generate-config not available on target; skipping capture"
  fi
fi

###############################################
# 1.5. Extract disk encryption key if present #
###############################################

disk_encryption_key_file=""
if sops -d "$nix_secrets_yaml" 2>/dev/null | grep -q "drive-encryption-keys:"; then
  blue "Extracting disk encryption key from secrets"
  install -d -m755 "$temp/tmp"
  sops -d --extract '["drive-encryption-keys"]["'"$target_hostname"'"]' "$nix_secrets_yaml" >"$temp/tmp/disk-secret.key"
  chmod 600 "$temp/tmp/disk-secret.key"
  disk_encryption_key_file="$temp/tmp/disk-secret.key"
  green "Disk encryption key ready for installation"
fi

#################################################
# 2. Run nixos-anywhere install (build locally) #
#################################################

blue "Running nixos-anywhere (build locally)"

# Clean & pre‑seed known_hosts
sed -i "/$target_hostname/d; /$target_destination/d" ~/.ssh/known_hosts || true
ssh-keyscan -p "$ssh_port" "$target_destination" 2>/dev/null >>~/.ssh/known_hosts || true

# Create temporary flake for initial install if secureboot is enabled
# This disables lanzaboote for the first install, which will be enabled after keys are generated
install_flake="$git_root#$target_hostname"
if [[ "$enable_secureboot" == "true" ]]; then
  blue "Creating temporary flake to disable lanzaboote for initial install..."
  install -d -m755 "$temp/install-flake"

  cat >"$temp/install-flake/flake.nix" <<EOF
{
  description = "Temporary flake for initial nixos-anywhere install";

  inputs.dotnix.url = "path:$git_root";

  outputs = { self, dotnix }: {
    nixosConfigurations.$target_hostname =
      dotnix.nixosConfigurations.$target_hostname.extendModules {
        modules = [({ lib, ... }: {
          # Disable lanzaboote for initial install (before keys exist)
          # Will be enabled automatically on first rebuild after keys are generated
          boot.lanzaboote.enable = lib.mkForce false;
        })];
      };
  };
}
EOF

  install_flake="$temp/install-flake#$target_hostname"
  green "Temporary flake created (lanzaboote disabled for initial install)"
fi

# Build nixos-anywhere command
nixos_anywhere_args=(
  --ssh-port "$ssh_port"
  --post-kexec-ssh-port "$ssh_port"
  --extra-files "$temp"
  --flake "$install_flake"
  --target-host "root@$target_destination"
)

# Add disk encryption key if present
if [[ -n "$disk_encryption_key_file" ]]; then
  nixos_anywhere_args+=(--disk-encryption-keys /tmp/disk-secret.key "$disk_encryption_key_file")
fi

SHELL=/bin/sh nix run github:nix-community/nixos-anywhere -- "${nixos_anywhere_args[@]}"

##############################################################
# 3. Prompt for password entry if encryption is enabled     #
##############################################################

if [[ "$enable_secureboot" == "true" ]]; then
  yellow "\n==================================================================="
  yellow "ACTION REQUIRED: Enter Encryption Password at Console"
  yellow "==================================================================="
  echo ""
  echo "The system has been installed with full-disk encryption."
  echo "TPM2 auto-unlock is NOT yet configured (Phase 2-3 will set this up)."
  echo ""
  echo "To proceed with Secure Boot and TPM2 setup:"
  echo "  1. Go to the server console"
  echo "  2. Enter the encryption password when prompted"
  echo "  3. Wait for the system to boot and become accessible via SSH"
  echo ""
  echo "The encryption password is stored in: drive-encryption-keys/$target_hostname"
  echo ""
  yellow "Press Enter once you have entered the password and the system is booting..."
  read -r
fi

#################################################
# 4. Sync repo to target                        #
#################################################

blue "Syncing dotnix repository to $target_hostname"

green "Adding $target_destination to local known_hosts"
ssh-keyscan -p "$ssh_port" "$target_destination" 2>/dev/null | grep -v '^#' >>~/.ssh/known_hosts || true

# Wait for system to be accessible
blue "Waiting for system to be accessible via SSH..."
max_attempts=30
attempt=0
while ! "${ssh_cmd[@]}" "echo 'SSH connection ready'" >/dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [ $attempt -ge $max_attempts ]; then
    red "Failed to connect to $target_hostname after $max_attempts attempts"
    red "Make sure you've entered the encryption password at the console"
    exit 1
  fi
  sleep 10
done
green "SSH connection established"

green "Syncing dotnix repository to $target_hostname:$nix_src_path"
sync "$target_user" "$git_root"
green "Syncing secrets repository to $target_hostname:$nix_src_path"
sync "$target_user" "$nix_secrets_dir"

############################################################
# 4.5. Phase 2+3: Secure Boot + TPM2 Setup (Combined)     #
############################################################

if [[ "$enable_secureboot" == "true" ]]; then
  blue "Phase 2+3: Setting up Secure Boot with lanzaboote and TPM2"

  # Generate Secure Boot keys
  blue "Generating Secure Boot keys..."
  "${ssh_cmd[@]}" "sudo sbctl create-keys"
  green "Secure Boot keys generated at /var/lib/sbctl/keys/"

  # Rebuild to enable lanzaboote (will auto-enable due to key presence)
  blue "Rebuilding system with lanzaboote..."
  "${ssh_cmd[@]}" "cd ~/$nix_src_path/dotnix && sudo nixos-rebuild boot --flake .#$target_hostname"
  green "System rebuilt with lanzaboote enabled (boot files signed)"

  # Verify signatures on boot files
  blue "Verifying boot file signatures..."
  if "${ssh_cmd[@]}" "sudo sbctl verify"; then
    green "All boot files are properly signed"
  else
    yellow "Warning: Some boot files may not be signed correctly"
  fi

  # Enroll Secure Boot keys in firmware
  blue "Enrolling Secure Boot keys in firmware..."
  if "${ssh_cmd[@]}" "sudo sbctl enroll-keys --microsoft"; then
    green "Secure Boot keys enrolled (will activate on next reboot)"
  else
    yellow "Warning: Secure Boot key enrollment had issues"
  fi

  # Reboot to activate lanzaboote and Secure Boot
  blue "Rebooting to activate lanzaboote and Secure Boot..."
  "${ssh_cmd[@]}" "sudo reboot" || true
  sleep 30

  # Wait for system to come back (user will enter password one last time)
  blue "Waiting for system to come back online (enter password at console)..."
  attempt=0
  while ! "${ssh_cmd[@]}" "echo 'SSH connection ready'" >/dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
      red "Failed to reconnect to $target_hostname after $max_attempts attempts"
      exit 1
    fi
    sleep 10
  done
  green "System is back online"

  # NOW verify Secure Boot is actually enabled
  blue "Verifying Secure Boot status..."
  if "${ssh_cmd[@]}" "sudo sbctl status | grep -q 'Secure Boot.*Enabled'"; then
    green "Secure Boot is now active"
  else
    red "ERROR: Secure Boot is still not enabled after sbctl enroll-keys"
    red "Cannot proceed with TPM2 enrollment"
    exit 1
  fi

  # NOW enroll TPM2 (with Secure Boot active, so PCR 7 has correct value)
  blue "Enrolling TPM2 for autonomous boot (with Secure Boot active)..."

  # Copy encryption key to remote system (ensuring no trailing newline)
  blue "Uploading encryption key for TPM2 enrollment..."
  "${scp_cmd[@]}" "$temp/tmp/disk-secret.key" "$target_user@$target_destination:/tmp/enroll-key.tmp"
  "${ssh_cmd[@]}" "sudo chmod 600 /tmp/enroll-key.tmp"

  # Enroll OS disk with TPM2
  blue "Enrolling OS disk (cryptroot) with TPM2 (PCR 7)..."
  if "${ssh_cmd[@]}" "sudo systemd-cryptenroll --unlock-key-file=/tmp/enroll-key.tmp --tpm2-device=auto --tpm2-pcrs=7 /dev/vda2"; then
    green "OS disk enrolled with TPM2"
  else
    yellow "Warning: OS disk TPM2 enrollment had issues (may already be enrolled)"
  fi

  # Enroll RAID with TPM2
  blue "Enrolling RAID (cryptraid) with TPM2 (PCR 7)..."
  if "${ssh_cmd[@]}" "sudo systemd-cryptenroll --unlock-key-file=/tmp/enroll-key.tmp --tpm2-device=auto --tpm2-pcrs=7 /dev/md/raid1p1"; then
    green "RAID enrolled with TPM2"
  else
    yellow "Warning: RAID TPM2 enrollment had issues (may already be enrolled)"
  fi

  # Clean up temporary key file
  "${ssh_cmd[@]}" "sudo rm -f /tmp/enroll-key.tmp"
  green "TPM2 enrollment complete"

  # Final reboot to test autonomous boot
  blue "Performing final reboot to test autonomous boot..."
  "${ssh_cmd[@]}" "sudo reboot" || true

  # Wait for autonomous boot
  blue "Waiting for autonomous boot to complete (this may take 1-2 minutes)..."
  sleep 60
  attempt=0
  while ! "${ssh_cmd[@]}" "echo 'SSH connection ready'" >/dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
      red "System did not come back online. Check console for issues."
      yellow "If password is required, Secure Boot may not be enabled or TPM2 enrollment failed."
      exit 1
    fi
    sleep 10
  done

  green "SUCCESS! System booted autonomously with TPM2 unlock and Secure Boot active"
  green "Phase 2+3 complete: Secure Boot and autonomous boot configured"
fi

#########################################################
# 5. Optionally git‑add, commit & push all changes     #
#########################################################

if yes_or_no "Stage, commit, and push all changes to Git?"; then
  nix fmt
  git -C "$git_root" add -A
  git -C "$git_root" commit -m "bootstrap: $target_hostname initial setup" || true
  git -C "$git_root" push || true
fi

########################
# 6. Finished summary  #
########################

if [[ "$enable_secureboot" == "true" ]]; then
  echo ""
  green "==================================================================="
  green "SUCCESS! $target_hostname is fully configured with Secure Boot"
  green "==================================================================="
  echo ""
  echo "Configuration summary:"
  echo "  ✓ NixOS installed with full-disk encryption"
  echo "  ✓ Secure Boot enabled with lanzaboote"
  echo "  ✓ TPM2 auto-unlock configured (PCR 7)"
  echo "  ✓ Autonomous boot active (no password required)"
  echo ""
  echo "Recovery information:"
  echo "  - Backup unlock key: drive-encryption-keys/$target_hostname (in sops secrets)"
  echo "  - If TPM fails: Boot to emergency shell, unlock manually with key"
  echo "  - Re-enroll TPM: sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7 <device>"
else
  green "Success! $target_hostname is now running dotnix."
fi

echo ""
echo "Next steps:"
echo "  ssh $target_user@$target_destination -p $ssh_port"
echo "  cd ~/$nix_src_path/dotnix && sudo nixos-rebuild switch --flake .#$target_hostname"
echo ""
