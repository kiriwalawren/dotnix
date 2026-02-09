{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.ui.nixos.hyprland.hyprmon;
in
{
  options.ui.nixos.hyprland.hyprmon = {
    enable = mkEnableOption "hyprmon";
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER,M,exec,${pkgs.kitty}/bin/kitty --class=hyprmon ${pkgs.hyprmon}/bin/hyprmon"
      ];
    };
  };
}
