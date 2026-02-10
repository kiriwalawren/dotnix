{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with builtins;
let
  cfg = config.ui.nixos.fuzzel;
in
{
  options.ui.nixos.fuzzel = {
    enable = mkEnableOption "fuzzel";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.fuzzel ];

    catppuccin.fuzzel.enable = true;
    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER,Space,exec,${pkgs.fuzzel}/bin/fuzzel"
      ];
    };

    programs.fuzzel = {
      enable = true;
    };
  };
}
