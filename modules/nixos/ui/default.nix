{
  pkgs,
  inputs,
  lib,
  config,
  theme,
  ...
}:
with lib; let
  cfg = config.ui;
in {
  imports = [
    inputs.catppuccin.nixosModules.catppuccin

    ./bluetooth.nix
    ./file-manager.nix
    ./fingerprint.nix
    ./gaming.nix
    ./hyprland.nix
    ./plymouth.nix
    ./sddm-theme.nix
    ./sound.nix
  ];

  meta.doc = lib.mdDoc ''
    NixOS UI configuration module with desktop environment components.

    When enabled, automatically enables: bluetooth, file manager, hyprland, plymouth, sddm theme, and sound.
    Also includes essential desktop applications: gnome-calculator, loupe, and zoom-us.
    Configures Catppuccin theming across the system.
  '';

  options.ui = {
    enable = mkEnableOption (lib.mdDoc "desktop environment with Wayland and theming");
  };

  config = mkIf cfg.enable {
    catppuccin.flavor = theme.variant;

    environment.systemPackages = with pkgs; [
      gnome-calculator
      loupe # Image Viewer
      zoom-us # Conferencing Software
    ];

    ui = {
      bluetooth.enable = true;
      fileManager.enable = true;
      hyprland.enable = true; # Tiling Manager
      plymouth.enable = true; # Boot Splash Screen
      sddmTheme.enable = true; # SDDM Display Manager Theme
      sound.enable = true;
    };
  };
}
