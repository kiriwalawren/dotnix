<h1 align="center">
  <img src="./.github/assets/flake.webp" width="250px"/>
  <br>
  Kiri's NixOS Flake
  <br>
  <a href='#'><img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png" width="600px"/></a>
  <br>
  <div>
    <a href="https://github.com/kiriwalawren/dotnix/issues">
        <img src="https://img.shields.io/github/issues/kiriwalawren/dotnix?color=f5a97f&labelColor=303446&style=for-the-badge">
    </a>
    <a href="https://github.com/kiriwalawren/dotnix/stargazers">
        <img src="https://img.shields.io/github/stars/kiriwalawren/dotnix?color=c6a0f6&labelColor=303446&style=for-the-badge">
    </a>
    <a href="https://github.com/kiriwalawren/dotnix">
        <img src="https://img.shields.io/github/repo-size/kiriwalawren/dotnix?color=ea999c&labelColor=303446&style=for-the-badge">
    </a>
    <a href="https://github.com/kiriwalawren/dotnix/blob/main/LICENSE">
        <img src="https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=GPL-3&logoColor=ca9ee6&colorA=313244&colorB=a6da95"/>
    </a>
    <a href="https://nixos.org">
        <img src="https://img.shields.io/badge/NixOS-unstable-blue.svg?style=for-the-badge&labelColor=303446&logo=NixOS&logoColor=white&color=91D7E3">
    </a>
  </div>
  <a href="https://builtwithnix.org">
      <img src="https://builtwithnix.org/badge.svg"/>
  </a>
</h1>

## Prequisites

- [Flakes](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/nixos-with-flakes-enabled) enabled

## Developing

Enter the development shell with `nix develop`. Run `nix fmt` to format the repo.

## Origin of the dendritic pattern

This repository follows [the dendritic pattern](https://github.com/mightyiam/dendritic).

## Automatic import

Nix files (they're all flake-parts modules) are automatically imported.
Nix files prefixed with an underscore are ignored.
No literal path imports are used.
This means files can be moved around and nested in directories freely.

## Installation

The `scripts/bootstrap-nixos.sh` script performs a one-shot NixOS install on a remote machine using [nixos-anywhere](https://github.com/nix-community/nixos-anywhere).

### Usage

```bash
./scripts/bootstrap-nixos.sh -n <hostname> -d <ip-or-domain> -k <ssh_key> [OPTIONS]
```

### Required arguments

| Flag | Description |
|------|-------------|
| `-n <hostname>` | Hostname as defined in the flake (e.g. `home-server`) |
| `-d <destination>` | IP or DNS of the target machine |
| `-k <ssh_key>` | Path to the private SSH key used for install |

### Options

| Flag | Description |
|------|-------------|
| `-u <user>` | SSH user with sudo (default: current user) |
| `--port <port>` | SSH port (default: `22`) |
| `--secureboot` | Enable Secure Boot + TPM2 auto-unlock setup |
| `--debug` | Enable bash xtrace for troubleshooting |
| `-h`, `--help` | Show help |

### What it does

1. Generates a target SSH host key and derives an age recipient so secrets are ready day-0
1. Optionally captures `hardware-configuration.nix` from the target before install
1. Extracts disk encryption keys from sops secrets (if configured)
1. Runs `nixos-anywhere` to install the flake on the target (builds locally)
1. Syncs the dotnix and secrets repositories to the target
1. With `--secureboot`: generates Secure Boot keys, rebuilds with lanzaboote, enrolls keys in firmware, and configures TPM2 auto-unlock
1. Optionally stages, commits, and pushes all changes to git

### Secure Boot configuration

Using `--secureboot` requires three pieces of configuration in the flake:

1. **Include the `encryption` module** in the host's module list (e.g. `modules/hosts/<hostname>/modules.nix`):

   ```nix
   configurations.nixos.<hostname>.modules = {
     inherit (config.flake.modules.nixos)
       base
       encryption  # provides lanzaboote, TPM2 initrd support, and sbctl/tpm2-tools
       # ...
       ;
   };
   ```

1. **Mark disk groups as encrypted** in the host's configuration (e.g. `modules/hosts/<hostname>/configuration.nix`):

   ```nix
   system.disks."/" = {
     devices = [ "/dev/nvme0n1" ];
     encryptDrives = true;  # wraps partitions in LUKS via disko
   };
   ```

   The `encryptionPasswordFile` option defaults to `/tmp/disk-secret.key`, which is where the bootstrap script places the key during install.

1. **Add an encryption key to the secrets repository** (`secrets.yaml`):

   ```yaml
   drive-encryption-keys:
     <hostname>: "your-encryption-password-here"
   ```

   The bootstrap script extracts this value via `sops -d --extract '["drive-encryption-keys"]["<hostname>"]'` and passes it to `nixos-anywhere` at install time.

### Special Thanks

- [mightyjam](https:/github.com/mightyjam/infra) for the Dendritic Pattern
- [nekowinston](https://github.com/nekowinston) for the nixppuccin wallpaper
- [redyf](https://github.com/redyf/nixdots) for the bar and some Hyprland configuration
- [sioodmy](https://github.com/sioodmy/dotfiles) for their NixOS and Hyprland configuration and badges
- [IogaMaster](https://github.com/IogaMaster/dotfiles) for the most beautiful catppuccin nix flake, some Hyprland config, and the badges
- [This reddit post](https://reddit.com/r/NixOS/comments/137j18j/comment/ju6h25k) for helping me figure out the bare minimum to get Hyprland running
  - AMD GPU minimum required config [here](./modules/nixos/ui/hyprland.nix)
