{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.ui.nixos.hyprland.hypridle;
in
{
  options.ui.nixos.hyprland.hypridle = {
    enable = mkEnableOption "hypridle";
  };

  config = mkIf cfg.enable {
    ui.nixos.hyprland.hyprlock.enable = true;

    services.hypridle = {
      enable = true;

      settings = {
        lockCmd = "pidof hyprlock || hyprlock"; # avoid starting multiple hyprlock instances
        beforeSleepCmd = "loginctl lock-session"; # Lock before suspend
        afterSleepCmd = "hyprctl dispatch dpms on"; # to avoid having to press a key twice to turn on the display

        listeners = [
          {
            timeout = 300; # 5 minutes
            onTimeout = "loginctl lock-session"; # lock screen when timeout has passed
          }
          {
            timeout = 330; # 5.5 minutes
            onTimeout = "hyprctl dispatch dpms off"; # screen off after timeout
            onResume = "hyprctl dispatch dpms on && brightnessctl -r"; # screen on when activity is detected after timeout has fired
          }
        ];
      };
    };
  };
}
