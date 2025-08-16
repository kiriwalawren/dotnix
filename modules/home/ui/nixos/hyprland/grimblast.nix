{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.ui.nixos.hyprland.grimblast;
in {
  meta.doc = lib.mdDoc ''
    Grimblast screenshot utility for Hyprland.
    
    Provides [Grimblast](https://github.com/hyprwm/contrib/tree/main/grimblast) with:
    - Screenshot keybindings: Ctrl+Shift+Alt+O (copy area), Ctrl+Shift+Alt+E (edit area)
    - [Pinta](https://pinta-project.com/) integration for screenshot editing
    - Environment variable configuration for consistent editor usage
  '';

  options.ui.nixos.hyprland.grimblast = {
    enable = mkEnableOption (lib.mdDoc "Grimblast screenshot utility");
  };

  config = mkIf cfg.enable {
    home.packages = [
      inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
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
