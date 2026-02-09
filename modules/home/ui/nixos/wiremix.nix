{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.ui.nixos.wiremix;
in
{
  options.ui.nixos.wiremix = {
    enable = mkEnableOption "wiremix";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.wiremix ];

    # Waybar integration - override the pulseaudio on-click
    programs.waybar.settings.mainBar.pulseaudio.on-click =
      "pkill wiremix || ${pkgs.kitty}/bin/kitty --class=wiremix ${pkgs.wiremix}/bin/wiremix";

    wayland.windowManager.hyprland.settings.windowrulev2 = [
      "float,class:(wiremix)"
      "center,class:(wiremix)"
      "size 750 700,class:(wiremix)"
      "stayfocused,class:(wiremix)"
    ];
  };
}
