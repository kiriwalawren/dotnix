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

## Origin of the dendritic pattern

This repository follows [the dendritic pattern](https://github.com/mightyiam/dendritic).

## Automatic import

Nix files (they're all flake-parts modules) are automatically imported.
Nix files prefixed with an underscore are ignored.
No literal path imports are used.
This means files can be moved around and nested in directories freely.

### Special Thanks

- [mightyjam](https:/github.com/mightyjam/infra) for the Dendritic Pattern
- [nekowinston](https://github.com/nekowinston) for the nixppuccin wallpaper
- [redyf](https://github.com/redyf/nixdots) for the bar and some Hyprland configuration
- [sioodmy](https://github.com/sioodmy/dotfiles) for their NixOS and Hyprland configuration and badges
- [IogaMaster](https://github.com/IogaMaster/dotfiles) for the most beautiful catppuccin nix flake, some Hyprland config, and the badges
- [This reddit post](https://reddit.com/r/NixOS/comments/137j18j/comment/ju6h25k) for helping me figure out the bare minimum to get Hyprland running
  - AMD GPU minimum required config [here](./modules/nixos/ui/hyprland.nix)
