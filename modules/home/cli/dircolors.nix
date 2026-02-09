{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.cli.dircolors;
in
{
  options.cli.dircolors = {
    enable = mkEnableOption "dircolors";
  };

  config = mkIf cfg.enable {
    programs.dircolors.enable = true;
  };
}
