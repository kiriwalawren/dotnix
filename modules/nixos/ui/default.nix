{
  pkgs,
  inputs,
  lib,
  config,
  theme,
  ...
}:
with lib;
let
  cfg = config.ui;
in
{
  imports = [
    inputs.catppuccin.nixosModules.catppuccin

    ./bluetooth.nix
    ./file-manager.nix
    ./fingerprint.nix
    ./fonts.nix
    ./gaming.nix
    ./greetd.nix
    ./hyprland.nix
    ./plymouth.nix
    ./sound.nix
    ./virtualisation.nix
  ];

  options.ui = {
    enable = mkEnableOption "ui";
  };

  config = mkIf cfg.enable {
    catppuccin = {
      enable = true;
      tty.enable = true;
      flavor = theme.variant;
      accent = theme.primaryAccent;
    };

    environment.systemPackages = with pkgs; [
      gnome-calculator
      loupe # Image Viewer
      zoom-us # Conferencing Software
    ];

    ui = {
      bluetooth.enable = true;
      fileManager.enable = true;
      fonts.enable = true; # Fonts
      greetd.enable = true; # greetd + tuigreet Display Manager
      hyprland.enable = true; # Tiling Manager
      plymouth.enable = true; # Boot Splash Screen
      sound.enable = true;
    };
  };
}
