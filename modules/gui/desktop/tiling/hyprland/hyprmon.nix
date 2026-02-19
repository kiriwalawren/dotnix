{ config, lib, ... }:
let
  wm = config.desktop.windowManager;
in
{
  flake.modules.homeManager.gui =
    { pkgs, ... }:
    {
      wayland.windowManager.hyprland.settings = lib.mkIf (wm == "hyprland") {
        bind = [
          "SUPER,M,exec,${pkgs.kitty}/bin/kitty --class=hyprmon ${pkgs.hyprmon}/bin/hyprmon"
        ];
      };
    };
}
