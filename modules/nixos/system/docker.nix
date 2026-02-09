{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.system.docker;
in
{
  options.system.docker = {
    enable = mkEnableOption "docker";
  };

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };

    users.extraGroups.docker.members = [ config.user.name ];
  };
}
