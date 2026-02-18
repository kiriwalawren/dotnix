{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.ui.apps.slack;
in
{
  options.ui.apps.slack = {
    enable = mkEnableOption "slack";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ slack ];
  };
}
