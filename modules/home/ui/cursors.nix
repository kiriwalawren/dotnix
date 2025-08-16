{
  lib,
  config,
  pkgs,
  theme,
  ...
}:
with lib; let
  cfg = config.ui.cursors;
in {
  meta.doc = lib.mdDoc ''
    Mouse cursor theming with Catppuccin design.

    Configures [Catppuccin cursors](https://github.com/catppuccin/cursors) for both GTK and X11 environments.
    Uses the theme variant and accent color from the global theme configuration.
  '';

  options.ui.cursors = {
    enable = mkEnableOption (lib.mdDoc "Catppuccin-themed mouse cursors");
  };

  config = mkIf cfg.enable {
    home.pointerCursor = {
      gtk.enable = true;
      x11.enable = true;

      name = "catppuccin-${theme.variant}-teal-cursors";
      package = pkgs.catppuccin-cursors."${theme.variant}Teal";
      size = 24;
    };
  };
}
