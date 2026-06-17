{ config, ... }:
let
  inherit (config) theme;
in
{
  flake.modules.homeManager.hyprland =
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
    };
}
