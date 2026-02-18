{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.ui.apps.teams;
in
{
  options.ui.apps.teams = {
    enable = mkEnableOption "teams";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ teams-for-linux ];
  };
}
