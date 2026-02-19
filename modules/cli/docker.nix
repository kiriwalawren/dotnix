{ config, ... }:
{
  flake.modules.nixos.docker = {
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
