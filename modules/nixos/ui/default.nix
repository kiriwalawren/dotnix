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
    ./greetd.nix
    ./hyprland.nix
    ./plymouth.nix
    ./sound.nix
  ];

  options.ui = {enable = mkEnableOption "ui";};

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
      greetd.enable = true; # greetd + tuigreet Display Manager
      hyprland.enable = true; # Tiling Manager
      plymouth.enable = true; # Boot Splash Screen
      sound.enable = true;
    };
  };
}
