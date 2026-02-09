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

    wayland.windowManager.hyprland.settings.windowrule = [
      "match:class wiremix, float on, center on, size 750 700, pin on, stay_focused on"
    ];
  };
}
