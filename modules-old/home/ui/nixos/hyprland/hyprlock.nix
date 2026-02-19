{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ui.nixos.hyprland.hyprlock;
in
{
  options.ui.nixos.hyprland.hyprlock = {
    enable = lib.mkEnableOption "hyprlock";
    fingerprint.enable = lib.mkEnableOption "fingerprint";
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf cfg.fingerprint.enable [ pkgs.polkit_gnome ];

    catppuccin.hyprlock.enable = true;

    programs.hyprlock = {
      enable = true;

      settings = {
        general = {
          hide_cursor = false;
        };

        auth = lib.mkIf cfg.fingerprint.enable {
          fingerprint.enabled = true;
        };

        background = [
          {
            monitor = "";
            path = "${config.theme.defaultWallpaper}";
          }
        ];
      };
    };

    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER,N,exec,hyprlock"
      ];
      exec-once = [
        (lib.mkIf cfg.fingerprint.enable "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1")
      ];
    };

    systemd.user.services.hyprlock-before-suspend = {
      Unit = {
        Description = "Lock with hyprlock before system suspend";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "hyprlock-dbus-suspend-watcher" ''
          ${pkgs.dbus}/bin/dbus-monitor --system "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" |
          while read -r line; do
            if echo "$line" | grep -q "true"; then
              ${pkgs.hyprlock}/bin/hyprlock
            fi
          done
        '';
        Restart = "always";
      };
    };
  };
}
