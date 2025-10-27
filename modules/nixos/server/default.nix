{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  inherit (config.server) globals;
  cfg = config.server;
in {
  imports = [./globals.nix ./radarr.nix];

  options.server = {
    enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "Whether or not to enable the nixarr module. Has the following features";
    };

    mediaUsers = mkOption {
      type = with types; listOf str;
      default = [config.user.name];
      example = ["user"];
      description = ''
        Extra users to add to the media group.
      '';
    };

    mediaDir = mkOption {
      type = types.path;
      default = "/data/media";
      example = "/data/media";
      description = ''
        The location of the media directory for the services.

        > **Warning:** Setting this to any path, where the subpath is not
        > owned by root, will fail! For example:
        >
        > ```nix
        >   mediaDir = /home/user/data
        > ```
        >
        > Is not supported, because `/home/user` is owned by `user`.
      '';
    };

    stateDir = mkOption {
      type = types.path;
      default = "/data/.state/services";
      example = "/data/.state/services";
      description = ''
        The location of the state directory for the services.

        > **Warning:** Setting this to any path, where the subpath is not
        > owned by root, will fail! For example:
        >
        > ```nix
        >   stateDir = /home/user/data/.state
        > ```
        >
        > Is not supported, because `/home/user` is owned by `user`.
      '';
    };
  };

  config = mkIf cfg.enable {
    users.groups.media.members = cfg.mediaUsers;

    # Create directories for all enabled services after /data is mounted
    systemd.services.server-setup-dirs = {
      description = "Create directories for media server services";
      wantedBy = ["multi-user.target"];
      after = ["unlock-raid.service"];
      requires = ["unlock-raid.service"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        # Base directories
        ${pkgs.coreutils}/bin/mkdir -p ${cfg.stateDir}
        ${pkgs.coreutils}/bin/chown root:root ${cfg.stateDir}
        ${pkgs.coreutils}/bin/chmod 0755 ${cfg.stateDir}

        ${pkgs.coreutils}/bin/mkdir -p ${cfg.mediaDir}
        ${pkgs.coreutils}/bin/chown ${globals.libraryOwner.user}:${globals.libraryOwner.group} ${cfg.mediaDir}
        ${pkgs.coreutils}/bin/chmod 0775 ${cfg.mediaDir}

        # Radarr directories
        ${optionalString cfg.radarr.enable ''
          ${pkgs.coreutils}/bin/mkdir -p ${cfg.stateDir}/radarr
          ${pkgs.coreutils}/bin/chown ${globals.radarr.user}:${globals.radarr.group} ${cfg.stateDir}/radarr
          ${pkgs.coreutils}/bin/chmod 0755 ${cfg.stateDir}/radarr

          ${pkgs.coreutils}/bin/mkdir -p ${cfg.mediaDir}/movies
          ${pkgs.coreutils}/bin/chown ${globals.libraryOwner.user}:${globals.libraryOwner.group} ${cfg.mediaDir}/movies
          ${pkgs.coreutils}/bin/chmod 0775 ${cfg.mediaDir}/movies
        ''}
      '';
    };

    server.radarr.enable = true;
  };
}
