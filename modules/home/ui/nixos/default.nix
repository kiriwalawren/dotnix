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
    ./gtk.nix
    ./hyprland
    ./impala.nix
    ./mako.nix
    ./waybar
    ./wofi.nix
  ];

  options.ui.nixos = {enable = mkEnableOption "nixos";};

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      wf-recorder
      wl-clipboard
    ];

    ui.nixos = {
      wofi.enable = true; # Application launcher
      gtk.enable = true;
      hyprland.enable = true; # Wayland Compositor (Tiling)
      impala.enable = true; # WiFi TUI launcher
      mako.enable = true; # Notification daemon
      waybar.enable = true; # Desktop Bar
    };
  };
}
