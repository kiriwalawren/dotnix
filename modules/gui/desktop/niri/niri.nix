{ inputs, config, ... }:
let
  inherit (config) theme;
in
{
  nixpkgs.overlays = [ inputs.niri.overlays.niri ];

  flake.modules.nixos.gui = {
    imports = [ inputs.niri.nixosModules.niri ];
  };

  flake.modules.nixos.niri =
    { pkgs, ... }:
    {
      programs.niri = {
        enable = true;
        package = pkgs.niri-unstable;
      };

      services.greetd.cmd = "niri";

      environment = {
        sessionVariables = {
          NIXOS_OZONE_WL = "1";
        };
      };

      xdg.portal.extraPortals = [
        pkgs.xdg-desktop-portal-gnome # Niri uses this for screensharing
      ];

      hardware.graphics.enable = true;
      services.dbus.enable = true;
    };

  flake.modules.homeManager.niri =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      rgba = color: "#${color}ee";
      primaryAccent = rgba config.catppuccin.colors.primaryAccent;
      secondaryAccent = rgba config.catppuccin.colors.secondaryAccent;
      crust = rgba config.catppuccin.colors.crust;
    in
    {
      home.sessionVariables.XDG_CURRENT_DESKTOP = "niri";

      programs.niri = {
        settings = {
          prefer-no-csd = true; # No title bars

          spawn-at-startup = [
            {
              command = [
                "systemctl"
                "--user"
                "import-environment"
                "WAYLAND_DISPLAY"
                "XDG_SESSION_TYPE"
              ];
            }
          ];

          xwayland-satellite = {
            enable = true;
            path = lib.getExe inputs.niri.packages."${pkgs.system}".xwayland-satellite-unstable;
          };

          animations = {
            slowdown = 0.1;
          };

          input = {
            focus-follows-mouse.enable = true;
            mouse = {
              accel-profile = "adaptive";
              accel-speed = .4;
              natural-scroll = false;
            };
            touchpad = {
              accel-profile = "adaptive";
              accel-speed = .4;
              natural-scroll = true;
            };
          };

          window-rules = [
            {
              geometry-corner-radius = {
                top-left = theme.radius;
                top-right = theme.radius;
                bottom-left = theme.radius;
                bottom-right = theme.radius;
              };
              clip-to-geometry = true;
            }
          ];

          layout = {
            gaps = 7;
            focus-ring = {
              width = 2;
              active.gradient = {
                from = primaryAccent;
                to = secondaryAccent;
                angle = 45;
              };
              inactive.color = crust;
            };
          };

          binds = {
            "XF86MonBrightnessUp".action.spawn = [
              (lib.getExe pkgs.brightnessctl)
              "set"
              "+10%"
            ];
            "XF86MonBrightnessDown".action.spawn = [
              (lib.getExe pkgs.brightnessctl)
              "set"
              "10%-"
            ];
            "Mod+Q".action.close-window = { };
            "Mod+F".action.maximize-column = { };

            # Movement
            "Mod+H".action.focus-column-left = { };
            "Mod+L".action.focus-column-right = { };
            "Mod+J".action.focus-window-down = { };
            "Mod+K".action.focus-window-up = { };

            "Mod+U".action.focus-workspace-up = { };
            "Mod+D".action.focus-workspace-down = { };

            "Mod+Shift+H".action.move-column-left = { };
            "Mod+Shift+L".action.move-column-right = { };
            "Mod+Shift+J".action.move-window-down = { };
            "Mod+Shift+K".action.move-window-up = { };

            "Mod+Shift+U".action.move-column-to-workspace-up = { };
            "Mod+Shift+D".action.move-column-to-workspace-down = { };

            # Resize
            "Mod+Equal".action.set-column-width = "+10%";
            "Mod+Minus".action.set-column-width = "-10%";

            # Color picker
            "Mod+P".action.spawn = [
              "${pkgs.hyprpicker}/bin/hyprpicker"
              "-a"
            ];
          };
        };
      };
    };
}
