{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.ui.nixos;
in {
  imports = [
    ./fuzzel.nix
    ./gtk.nix
    ./hyprland
    ./mako.nix
    ./waybar
  ];

  meta.doc = lib.mdDoc ''
    NixOS-specific UI components for Wayland desktop environment.

    When enabled, automatically enables: fuzzel, gtk, hyprland, mako, and waybar.
    Also includes wf-recorder for screen recording and wl-clipboard for clipboard management.
    Designed specifically for NixOS Wayland environments.
  '';

  options.ui.nixos = {
    enable = mkEnableOption (lib.mdDoc "NixOS Wayland desktop environment components");
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      wf-recorder
      wl-clipboard
    ];

    ui.nixos = {
      fuzzel.enable = true; # Application launcher
      gtk.enable = true;
      hyprland.enable = true; # Wayland Compositor (Tiling)
      mako.enable = true; # Notification daemon
      waybar.enable = true; # Desktop Bar
    };
  };
}
