{
  config,
  lib,
  theme,
  ...
}:
with lib; let
  cfg = config.ui.apps.kitty;
in {
  options.ui.apps.kitty = {enable = mkEnableOption "kitty";};

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      themeFile = "Catppuccin-${theme.variantUpper}";

      font = {
        name = theme.font;
        size = theme.fontSize;
      };

      settings = {
        confirm_os_window_close = "0";
        copy_on_select = "clipboard";
        term = "xterm-256color";

        background_opacity = ".85";
      };
    };

    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER,Return,exec,kitty"
      ];
    };
  };
}
