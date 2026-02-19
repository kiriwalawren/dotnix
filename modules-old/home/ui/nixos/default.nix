{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.ui.nixos;
in
{
  imports = [
    ./fuzzel.nix
    ./gtk.nix
    ./hyprland
    ./impala.nix
    ./mako.nix
    ./waybar
    ./wiremix.nix
    ./wofi.nix
  ];

  options.ui.nixos = {
    enable = mkEnableOption "nixos";
  };

  config = mkIf cfg.enable {
    # recorder goes with slack
    home.packages = with pkgs; [
      wf-recorder
    ];

    ui.nixos = {
      wofi.enable = false; # Application launcher
      fuzzel.enable = true; # Application launcher
      gtk.enable = true;
      hyprland.enable = true; # Wayland Compositor (Tiling)
      impala.enable = true; # WiFi TUI launcher
      wiremix.enable = true; # Audio Mixer
      mako.enable = true; # Notification daemon
      waybar.enable = true; # Desktop Bar
    };
  };
}
