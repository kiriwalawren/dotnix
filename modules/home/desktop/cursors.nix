{
  lib,
  config,
  pkgs,
  theme,
  ...
}:
with lib; let
  cfg = config.modules.desktop.cursors;
in {
  options.modules.desktop.cursors = {enable = mkEnableOption "cursors";};

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
