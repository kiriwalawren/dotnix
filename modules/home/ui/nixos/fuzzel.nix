{
  pkgs,
  config,
  lib,
  theme,
  ...
}:
with lib;
with builtins; let
  cfg = config.ui.nixos.fuzzel;
in {
  options.ui.nixos.fuzzel = {enable = mkEnableOption "fuzzel";};

  config = mkIf cfg.enable {
    ui.fonts.enable = true;

    programs.fuzzel = {
      enable = true;

      settings = {
        main = {
          terminal = "${pkgs.kitty}/bin/kitty";
          line-height = 20;
        };

        border = {
          inherit (theme) radius;
          width = 2;
        };

        colors = with theme.colors; {
          background = "${base}ff";
          text = "${text}ff";
          match = "${primaryAccent}ff";
          selection = "${surface2}ff";
          selection-match = "${primaryAccent}ff";
          selection-text = "${text}ff";
          border = "${secondaryAccent}ff";
        };
      };
    };

    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER,Space,exec,fuzzel"
      ];
    };
  };
}
