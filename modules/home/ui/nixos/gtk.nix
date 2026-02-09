{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.ui.nixos.gtk;
in
{
  options.ui.nixos.gtk = {
    enable = mkEnableOption "gtk";
  };

  config = mkIf cfg.enable {
    xdg.enable = true;

    catppuccin.gtk.enable = true;
    gtk = {
      enable = true;
    };
  };
}
