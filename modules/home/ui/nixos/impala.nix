{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ui.nixos.impala;
in {
  options.ui.nixos.impala = {enable = mkEnableOption "impala";};

  config = mkIf cfg.enable {
    home.packages = [pkgs.impala];

    # Waybar integration - override the network on-click
    programs.waybar.settings.mainBar.network.on-click = "pkill impala || ${pkgs.kitty}/bin/kitty --class=impala ${pkgs.impala}/bin/impala";

    wayland.windowManager.hyprland.settings.windowrulev2 = [
      "float,class:(impala)"
      "center,class:(impala)"
      "size 1100 700,class:(impala)"
      "stayfocused,class:(impala)"
    ];
  };
}
