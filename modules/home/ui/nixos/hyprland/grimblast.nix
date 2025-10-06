{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.ui.nixos.hyprland.grimblast;
in {
  options.ui.nixos.hyprland.grimblast = {enable = mkEnableOption "grimblast";};

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.hyprland-contrib.grimblast
    ];

    home.sessionVariables = {
      GRIMBLAST_EDITOR = "${pkgs.pinta}/bin/pinta";
    };

    wayland.windowManager.hyprland.settings = {
      env = [
        "GRIMBLAST_EDITOR,${pkgs.pinta}/bin/pinta"
      ];

      bind = [
        "CONTROLSHIFTALT,O,exec,grimblast copy area"
        "CONTROLSHIFTALT,E,exec,grimblast edit area"
      ];
    };
  };
}
