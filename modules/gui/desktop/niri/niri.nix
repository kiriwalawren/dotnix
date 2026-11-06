{ config, self, ... }:
let
  inherit (config) theme;
in
{
  flake.wrappers.niri =
    {
      lib,
      pkgs,
      wlib,
      ...
    }:
    let
      rgba = color: "#${color}ee";
      primaryAccent = rgba config.catppuccin.colors.primaryAccent;
      secondaryAccent = rgba config.catppuccin.colors.secondaryAccent;
      crust = rgba config.catppuccin.colors.crust;
      base = rgba config.catppuccin.colors.base;
      overlay = rgba config.catppuccin.colors.overlay0;
      red = rgba config.catppuccin.colors.red;
    in
    {
      imports = [ wlib.wrapperModules.niri ];

      settings =
        let
          flag = _: { };
        in
        {
          prefer-no-csd = true; # No title bars
          hotkey-overlay.skip-at-startup = true;

          spawn-at-startup = [
            "systemctl"
            "--user"
            "import-environment"
            "WAYLAND_DISPLAY"
            "XDG_SESSION_TYPE"
          ];

          xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

          animations = {
            slowdown = 0.1;
          };

          input = {
            mouse = {
              accel-profile = "adaptive";
              accel-speed = .4;
            };
            touchpad = {
              click-method = "clickfinger";
              accel-profile = "adaptive";
              accel-speed = .4;
              natural-scroll = flag;
              dwt = flag; # Palm rejection while typing
            };
          };

          window-rules = [
            {
              geometry-corner-radius = theme.radius;
              clip-to-geometry = true;
            }
            {
              excludes = [
                { app-id = ".gimp-2.10-wrapped_"; }
                { app-id = "Geeqie"; }
                { app-id = "Loupe"; }
                { app-id = "darktable"; }
                { app-id = "firefox"; }
                { app-id = "imv"; }
                { app-id = "com.jeffser.Nocturne"; }
                { app-id = "plezy"; }
                { app-id = "qimgv"; }
                { app-id = "rapidraw"; }
                { app-id = "zen"; }
                { app-id = "zen-beta"; }
              ];
              opacity = .85;
            }
          ];

          layout = {
            gaps = 7;
            focus-ring = {
              width = 2;
              active-gradient = _: {
                props = {
                  from = primaryAccent;
                  to = secondaryAccent;
                  angle = 45;
                };
              };
              inactive-color = crust;
            };
          };

          recent-windows = {
            highlight = {
              corner-radius = theme.radius;
              active-color = overlay;
              urgent-color = red;
            };
          };

          overview = {
            backdrop-color = base;
          };

          binds =
            let
              niri =
                cmd:
                [
                  "niri"
                  "msg"
                  "action"
                ]
                ++ (lib.splitString " " cmd);
            in
            {
              "Mod+Ctrl+Alt+Shift+Q".spawn = niri "close-window";
              "Mod+Ctrl+Alt+Shift+F".spawn = niri "maximize-column";

              # Movement
              "Mod+Ctrl+Alt+Shift+H".spawn = niri "focus-column-left";
              "Mod+Ctrl+Alt+Shift+L".spawn = niri "focus-column-right";
              "Mod+Ctrl+Alt+Shift+J".spawn = niri "focus-window-down";
              "Mod+Ctrl+Alt+Shift+K".spawn = niri "focus-window-up";

              "Mod+Ctrl+Alt+Shift+U".spawn = niri "focus-workspace-up";
              "Mod+Ctrl+Alt+Shift+D".spawn = niri "focus-workspace-down";

              "Ctrl+Alt+Shift+H".spawn = niri "move-column-left";
              "Ctrl+Alt+Shift+L".spawn = niri "move-column-right";
              "Ctrl+Alt+Shift+J".spawn = niri "move-window-down";
              "Ctrl+Alt+Shift+K".spawn = niri "move-window-up";

              "Ctrl+Alt+Shift+U".spawn = niri "move-column-to-workspace-up";
              "Ctrl+Alt+Shift+D".spawn = niri "move-column-to-workspace-down";

              # Resize
              "Mod+Ctrl+Alt+Shift+Equal".spawn = niri "set-column-width +10%";
              "Mod+Ctrl+Alt+Shift+Minus".spawn = niri "set-column-width -10%";

              # Color picker
              # Hyprpicker is better than niri's color picker
              "Mod+Ctrl+Alt+Shift+P".spawn = [
                "${pkgs.hyprpicker}/bin/hyprpicker"
                "-a"
              ];
            };
        };
    };

  flake.modules.nixos.niri = { pkgs, ... }: {
    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.niri;
    };

    services.greetd.cmd = "niri-session";

    environment = {
      sessionVariables = {
        NIXOS_OZONE_WL = "1";
      };
    };

    hardware.graphics.enable = true;
    services.dbus.enable = true;
  };

  flake.modules.homeManager.niri = {
    home.sessionVariables.XDG_CURRENT_DESKTOP = "niri";
  };
}
