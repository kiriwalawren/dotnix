{
  config,
  lib,
  ...
}:
with lib;
with builtins;
let
  cfg = config.ui.nixos.mako;
in
{
  options.ui.nixos.mako = {
    enable = mkEnableOption "mako";
  };

  config = mkIf cfg.enable {
    catppuccin.mako.enable = true;

    services.mako = {
      enable = true;
      settings = {
        anchor = "bottom-right";
        border-radius = config.theme.radius;
        default-timeout = 10000; # 10s
        height = 300;
        width = 400;
      };
    };
  };
}
