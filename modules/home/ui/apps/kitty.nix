{
  config,
  lib,
  theme,
  ...
}:
with lib; let
  cfg = config.ui.apps.kitty;
in {
  meta.doc = lib.mdDoc ''
    Kitty terminal emulator with Catppuccin theming and Hyprland integration.

    Configures [Kitty](https://sw.kovidgoyal.net/kitty/) with theme-aware styling,
    font configuration from global theme, and custom keybind (Ctrl+Shift+Alt+T)
    for launching from Hyprland. Automatically enables fonts module.
  '';

  options.ui.apps.kitty = {
    enable = mkEnableOption (lib.mdDoc "Kitty terminal emulator with theming");
  };

  config = mkIf cfg.enable {
    ui.fonts.enable = true;

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
        "CONTROLSHIFTALT,T,exec,kitty"
      ];
    };
  };
}
