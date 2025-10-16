{
  config,
  hostConfig,
  lib,
  pkgs,
  theme,
  ...
}:
with theme.colors;
with lib; let
  inherit (hostConfig.ui) fingerprint;
  cfg = config.ui.nixos.hyprland.hyprlock;
in {
  options.ui.nixos.hyprland.hyprlock = {enable = mkEnableOption "hyprlock";};

  config = mkIf cfg.enable {
    home.packages = mkIf fingerprint.enable [pkgs.polkit_gnome];

    programs.hyprlock = {
      enable = true;

      settings = {
        general = {
          hide_cursor = false;
        };

        auth = mkIf fingerprint.enable {
          fingerprint.enabled = true;
        };

        background = [
          {
            monitor = "";
            path = "${theme.defaultWallpaper}";
          }
        ];

        input-field = [
          {
            monitor = "";

            size = "300, 50";

            outline_thickness = 2;

            outer_color = "rgb(${primaryAccent})";
            inner_color = "rgb(${base})";
            font_color = "rgb(${text})";
            fail_color = "rgb(${red})";
            rounding = theme.radius;

            fade_on_empty = false;
            placeholder_text = ''<span font_family="${theme.font}" foreground="##${subtext1}">Password...</span>'';

            dots_spacing = 0.3;
            dots_center = true;
          }
        ];

        label = [
          {
            monitor = "";
            text = "$TIME";
            font_family = theme.font;
            font_size = 64;
            color = "rgb(${lavender})";

            position = "0, 80";

            valign = "center";
            halign = "center";
          }
        ];
      };
    };

    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER,L,exec,hyprlock"
      ];
      exec-once = [
        (mkIf fingerprint.enable "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1")
      ];
    };

    systemd.user.services.hyprlock-before-suspend = {
      Unit = {
        Description = "Lock with hyprlock before system suspend";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };

      Install = {
        WantedBy = ["graphical-session.target"];
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
