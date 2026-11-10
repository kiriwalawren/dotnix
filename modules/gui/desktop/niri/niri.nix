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
                { app-id = "blender"; }
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
              bind = import ./_bind.nix;
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
              "Mod+Ctrl+Alt+Shift+Q" = bind "Close window" { spawn = niri "close-window"; };
              "Mod+Ctrl+Alt+Shift+F" = bind "Maximize column" { spawn = niri "maximize-column"; };
              "Ctrl+Alt+Shift+F" = bind "Maximize column" { spawn = niri "maximize-column"; };

              # Movement
              "Mod+Ctrl+Alt+Shift+H" = bind "Focus column left" { spawn = niri "focus-column-left"; };
              "Mod+Ctrl+Alt+Shift+L" = bind "Focus column right" { spawn = niri "focus-column-right"; };
              "Mod+Ctrl+Alt+Shift+J" = bind "Focus window down" { spawn = niri "focus-window-down"; };
              "Mod+Ctrl+Alt+Shift+K" = bind "Focus window up" { spawn = niri "focus-window-up"; };

              "Mod+Ctrl+Alt+Shift+U" = bind "Focus workspace up" { spawn = niri "focus-workspace-up"; };
              "Mod+Ctrl+Alt+Shift+D" = bind "Focus workspace down" { spawn = niri "focus-workspace-down"; };

              "Ctrl+Alt+Shift+H" = bind "Move column left" { spawn = niri "move-column-left"; };
              "Ctrl+Alt+Shift+L" = bind "Move column right" { spawn = niri "move-column-right"; };
              "Ctrl+Alt+Shift+J" = bind "Move window down" { spawn = niri "move-window-down"; };
              "Ctrl+Alt+Shift+K" = bind "Move window up" { spawn = niri "move-window-up"; };

              "Ctrl+Alt+Shift+U" = bind "Move column to workspace up" {
                spawn = niri "move-column-to-workspace-up";
              };
              "Ctrl+Alt+Shift+D" = bind "Move column to workspace down" {
                spawn = niri "move-column-to-workspace-down";
              };

              # Resize
              "Ctrl+Alt+Shift+B" = bind "Widen column" { spawn = niri "set-column-width +10%"; };
              "Ctrl+Alt+Shift+S" = bind "Narrow column" { spawn = niri "set-column-width -10%"; };

              # Color picker
              # Hyprpicker is better than niri's color picker
              "Mod+Ctrl+Alt+Shift+P" = bind "Color picker" {
                spawn = [
                  "${pkgs.hyprpicker}/bin/hyprpicker"
                  "-a"
                ];
              };
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
