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

## Hosts

### Prequisites

- [Flakes](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/nixos-with-flakes-enabled) enabled

### [NixOS WSL](https://github.com/nix-community/NixOS-WSL)

#### Installing

1. Run the following command:
   ```sh
   sudo nixos-rebuild switch --flake github:kiriwalawren/dotnix/main#nixos-wsl
   ```

### [NixOS Desktop](https://nixos.org/download)

#### Installing

1. Run the following command:
   ```sh
   sudo nixos-rebuild switch --flake github:kiriwalawren/dotnix/main#nixos-desktop
   ```

## Rebuilding

If you have the repo cloned locally at `~/gitrepos/dotnix`, you can rebuild with the following:

```sh
nh os switch
```

## Architecture

This flake uses a **cascading options approach** instead of traditional manual module imports. All modules are imported into every host, and hosts simply enable what they need through options.

### Traditional Approach (Not Used)

```nix
# Traditional - manual imports everywhere
imports = [
  ../modules/home/cli/git.nix
  ../modules/home/cli/fish.nix
  ../modules/nixos/ui/gaming.nix
  # ... many more imports
];
```

### Cascading Options Approach (Used Here)

```nix
# Cascading - clean declarative interface
cli.enable = true;        # Enables all CLI tools
ui.gaming.enable = true;  # Just gaming
ui.apps.firefox.enable = true;  # Individual apps
```

This keeps host declarations **concise and readable** while making all shared configuration automatically available.

## Folder Structure

```
├── flake.nix              # Main flake entry point
├── hosts/                 # Host-specific configuration
│   ├── default.nix        # Host declarations with cascading options
│   ├── disko.nix          # Declarative disk configuration
│   └── hardware/          # Hardware-specific, non-shareable configs
├── modules/               # All reusable configuration modules
│   ├── home/              # Home Manager (~/) user environment
│   │   ├── cli/           # Command-line tools and development
│   │   └── ui/            # Desktop applications and theming
│   │       ├── apps/      # Cross-platform desktop applications
│   │       └── nixos/     # User configs for custom desktop environments
│   └── nixos/             # System-level configuration
│       ├── system/        # Core system services
│       └── ui/            # Desktop environment components
├── theme/                 # Global theming system
│   ├── default.nix        # Theme configuration
│   └── wallpapers/        # Background images
├── checks/                # Nix validation (format.nix, statix.nix)
├── scripts/               # Bootstrap and setup scripts
├── nixos-bootstrapper/    # Minimal configs for quick SSH access
└── secrets.yaml           # Encrypted secrets via SOPS
```

### Key Directories

- **`hosts/`** - Small, focused host declarations that enable features
- **`modules/home/`** - User environment managed by Home Manager
  - **`cli/`** - Command-line tools (work everywhere)
  - **`ui/apps/`** - Desktop applications (work on any GUI system)
  - **`ui/nixos/`** - User configs for building desktop environments from scratch
- **`modules/nixos/`** - System-level configuration and services
- **`theme/`** - Centralized theming (planned migration to Stylix)
- **`checks/`** - CI validation with `nix flake check`

## Module Documentation

Detailed documentation for each module is available in the auto-generated NixOS manual and can be viewed using:

```bash
nix-instantiate --eval --json --expr '(import <nixpkgs/nixos> {}).options' | jq
```

Or by browsing the inline documentation in each module's source code.

### Special Thanks

- [nekowinston](https://github.com/nekowinston) for the nixppuccin wallpaper
- [redyf](https://github.com/redyf/nixdots) for the bar and some Hyprland configuration
- [sioodmy](https://github.com/sioodmy/dotfiles) for their NixOS and Hyprland configuration and badges
- [IogaMaster](https://github.com/IogaMaster/dotfiles) for the most beautiful catppuccin nix flake, some Hyprland config, and the badges
- [This reddit post](https://reddit.com/r/NixOS/comments/137j18j/comment/ju6h25k) for helping me figure out the bare minimum to get Hyprland running
  - AMD GPU minimum required config [here](./modules/nixos/ui/hyprland.nix)
