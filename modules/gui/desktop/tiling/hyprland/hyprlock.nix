{ config, lib, ... }:
let
  wm = config.desktop.windowManager;
  inherit (config) theme;
in
{
  flake.modules.homeManager.gui = lib.mkIf (wm == "hyprland") (
    { pkgs, ... }:
    {
      catppuccin.hyprlock.enable = true;

      programs.hyprlock = {
        enable = true;

        settings = {
          general = {
            hide_cursor = false;
          };

          background = [
            {
              monitor = "";
              path = "${theme.defaultWallpaper}";
            }
          ];
        };
      };

      wayland.windowManager.hyprland.settings = {
        bind = [
          "SUPER,N,exec,hyprlock"
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
    }
  );
}
