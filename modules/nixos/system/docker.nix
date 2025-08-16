{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.system.docker;
in {
  meta.doc = lib.mdDoc ''
    Docker containerization platform with rootless configuration.

    Enables [Docker](https://www.docker.com/) with rootless mode for enhanced security.
    Automatically adds the configured user to the docker group for container management.
  '';

  options.system.docker = {
    enable = mkEnableOption (lib.mdDoc "Docker with rootless configuration");
  };

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };

    users.extraGroups.docker.members = [config.user.name];
  };
}
