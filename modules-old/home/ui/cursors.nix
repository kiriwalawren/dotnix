{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.ui.cursors;
in
{
  options.ui.cursors = {
    enable = mkEnableOption "cursors";
  };

  config = mkIf cfg.enable {
    catppuccin.cursors.enable = true;

    home.pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      size = 24;
    };
  };
}
