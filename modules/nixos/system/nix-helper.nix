{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.system.nix-helper;
in
{
  options.system.nix-helper = {
    enable = mkEnableOption "nix-helper";
  };

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;

      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep-since 10d --keep 10";
      };

      flake = "/home/${config.user.name}/gitrepos/dotnix";
    };
  };
}
