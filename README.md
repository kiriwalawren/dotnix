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

## NixOS Modules

### System

#### [User](./modules/nixos/system/user/default.nix)

Configures a user for the NixOS system using a dynamic user name that can be configured in `nixosConfiguration`.

```nix
user.name = "kiri"; # Defaults to "walawren"
```

Each unique value used for `user.name` needs to have a corresponding SSH key added to the `private_keys` object of `secrets.yaml`.

### UI

#### [File Manager](./modules/nixos/ui/file-manager.nix)

Configures a file explorer;

#### [Gaming](./modules/nixos/ui/gaming.nix)

Configures gaming for NixOS. Includes [steam](https://store.steampowered.com/about/), [protonup](https://github.com/AUNaseef/protonup), and [heroic](https://heroicgameslauncher.com/).

#### [Hyprland](./modules/nixos/ui/hyprland)

Bare bones installation of the [Hyprland](https://hyprland.org) dynamic tiling Wayland compositor.

This is the starting point for configuring a UI for NixOS.

#### [Plymouth](./modules/nixos/ui/plymouth.nix)

Configures a customizable boot splash screen called [Plymouth](https://gitlab.freedesktop.org/plymouth/plymouth).

#### [Sound](./modules/nixos/ui/sound.nix)

Configures sound for NixOS.

### [Home](./modules/nixos/home.nix)

Configures Home Manager to be managed by the system for the configured user.

Downside: Changes to [home modules](./modules/home) require full system rebuild.

Upside: ONE COMMAND TO RULE THEM ALL (`nh os switch`).

## [Home Modules](./modules/home)

[Home Manager](https://github.com/nix-community/home-manager) configuration

### CLI

Contains toggleable modules for the following:

- [btop](https://github.com/aristocratos/btop) - Resource monitor
- [dircolors](https://www.gnu.org/software/coreutils/manual/html_node/dircolors-invocation.html#dircolors-invocation) - Folder colors for ls (and dir, etc.)
- [direnv](https://direnv.net/) - Auto change dev environment on changing directory
- [fish](https://fishshell.com) - Shell
- [git](https://git-scm.com/) - Version control
- [neovim](https://neovim.io/) - Neovim terminal text editor using [nixvim](https://github.com/nix-community/nixvim)
- [tmux](https://github.com/tmux/tmux/wiki) - Terminal multiplexer

The [cli module](./modules/home/cli/default.nix) will enable all of the above.

```nix
imports = [ ./modules/home ];

cli.enable = true;
```

Each module can be individually enabled as well.

```nix
imports = [ ./modules/home ];

cli.git.enable = true;
cli.fish.enable = true;
...
```

### UI

```nix
imports = [ ./modules/home ];

ui.enable = true;
```

Enables [CLI](#cli) and [Apps](#apps) by default.

#### Apps

Contains UI based app installations and configurations.

The following are also installed and configured:

- User settings for Hyprland
- [Firefox](https://www.mozilla.org/en-US/firefox/new) - Browser
- [kitty](https://sw.kovidgoyal.net/kitty)- Terminal emulator
- [Slack](https://slack.com/) - Teams communication
- [Spotify](https://www.spotify.com/us/download/linux/) - Music streaming client
- [Teams for Linux](https://github.com/IsmaelMartinez/teams-for-linux) - Teams communication
- [Vesktop](https://github.com/Vencord/Vesktop) - Custom Discord client with [Vencord](https://vencord.dev/) preinstalled

```nix
imports = [ ./modules/home ];

ui.apps.enable = true;
```

Each module can be individually enabled as well.

```nix
imports = [ ./modules/home ];

ui.apps.firefox.enable = true;
ui.apps.kitty.enable = true;
...
```

#### NixOS

Contains NixOS UI user configurations.

Requires [Hyprland](#hyprland) configuration first.

The following are also installed and configured:

- [Grimblast](https://github.com/hyprwm/contrib/tree/main/grimblast) screenshot utility
- [Hyprlock](https://github.com/hyprwm/hyprlock) lock screen
- [Hypridle](https://github.com/hyprwm/hypridle) idle daemon
- [Hyprpaper](https://github.com/hyprwm/hyprpaper) wallpaper utility and selector
- [fuzzel](https://codeberg.org/dnkl/fuzzel) app launcher

```nix
imports = [ ./modules/home ];

ui.nixos.enable = true; # Defaults to true
```

Each module can be individually enabled as well.

```nix
imports = [ ./modules/home ];

ui.nixos.hyprland.enable = true;
ui.nixos.fuzzel.enable = true;
...
```

### Special Thanks

- [nekowinston](https://github.com/nekowinston) for the nixppuccin wallpaper
- [redyf](https://github.com/redyf/nixdots) for the bar and some Hyprland configuration
- [sioodmy](https://github.com/sioodmy/dotfiles) for their NixOS and Hyprland configuration and badges
- [IogaMaster](https://github.com/IogaMaster/dotfiles) for the most beautiful catppuccin nix flake, some Hyprland config, and the badges
- [This reddit post](https://reddit.com/r/NixOS/comments/137j18j/comment/ju6h25k) for helping me figure out the bare minimum to get Hyprland running
  - AMD GPU minimum required config [here](./modules/nixos/ui/hyprland.nix)
