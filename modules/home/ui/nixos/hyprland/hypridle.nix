{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.ui.nixos.hyprland.hypridle;
in {
  meta.doc = lib.mdDoc ''
    Automatic idle management and screen locking daemon for Hyprland.

    Provides intelligent power management:
    - Automatic screen locking after 5 minutes of inactivity
    - Integration with system suspend/sleep events
    - Pre-suspend screen locking for security
    - Display power management with proper wake handling
    - Prevention of multiple hyprlock instances
    - Seamless integration with loginctl session management

    Essential for maintaining security and power efficiency by automatically
    locking the screen and managing display power states during idle periods.

    Links: [hypridle](https://github.com/hyprwm/hypridle)
  '';

  options.ui.nixos.hyprland.hypridle = {enable = mkEnableOption (lib.mdDoc "hypridle automatic idle management for Hyprland");};

  config = mkIf cfg.enable {
    ui.nixos.hyprland.hyprlock.enable = true;

    services.hypridle = {
      enable = true;

      settings = {
        lockCmd = "pidof hyprlock || ${lib.getExe config.programs.hyprlock.package}"; # avoid starting multiple hyprlock instances
        beforeSleepCmd = "loginctl lock-session"; # Lock before suspend
        afterSleepCmd = "hyprctl dispatch dpms on"; # to avoid having to press a key twice to turn on the display

        listeners = [
          {
            timeout = 300; # 5 minutes
            onTimeout = "loginctl lock-session"; # lock screen when timeout has passed
          }
          # {
          #   timeout = 600; # 10 minutes
          #   onTimeout = "hyprctl dispatch dpms off"; # screen off after timeout
          #   onResume = "hyprctl dispatch dpms on"; # screen on when activity is detected after timeout has fired
          # }
        ];
      };
    };
  };
}
