{ inputs, ... }:
{
  nixpkgs.overlays = [ inputs.niri.overlays.niri ];

  flake.modules.nixos.gui = {
    imports = [ inputs.niri.nixosModules.niri ];
  };

  flake.modules.nixos.niri =
    { pkgs, lib, ... }:
    {
      programs.niri.enable = true;

      environment = {
        systemPackages = [ pkgs.brightnessctl ];
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
      pkgs,
      lib,
      config,
      ...
    }:
    let
      rgba = color: "#${color}ee";
      primaryAccent = rgba config.catppuccin.colors.primaryAccent;
      secondaryAccent = rgba config.catppuccin.colors.secondaryAccent;
      crust = rgba config.catppuccin.colors.crust;
    in
    {
      programs.niri = {
        settings = {
          input = {
            mouse = {
              accel-profile = "adaptive";
              accel-speed = 0.4;
            };
          };

          layout = {
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
              "brightnessctl"
              "set"
              "+10%"
            ];
            "XF86MonBrightnessDown".action.spawn = [
              "brightnessctl"
              "set"
              "10%-"
            ];
            "Mod+Q".action.close-window = { };
            "Mod+F".action.maximize-column = { };
          };
        };
      };
    };
}
