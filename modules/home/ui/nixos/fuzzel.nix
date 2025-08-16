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
  meta.doc = lib.mdDoc ''
    Fuzzel application launcher for Wayland with Catppuccin theming.

    Configures [Fuzzel](https://codeberg.org/dnkl/fuzzel) with theme-aware colors,
    custom keybind (Ctrl+Shift+Alt+A), and Kitty terminal integration.
    Automatically enables fonts module.
  '';

  options.ui.nixos.fuzzel = {
    enable = mkEnableOption (lib.mdDoc "Fuzzel application launcher");
  };

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
        "CONTROLSHIFTALT,A,exec,fuzzel"
      ];
    };
  };
}
