{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.cli.restish;
in {
  options.cli.restish = {enable = mkEnableOption "restish";};
  config = mkIf cfg.enable {
    home.packages = [pkgs.restish];
  };
}
