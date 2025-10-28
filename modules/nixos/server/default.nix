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
  imports = [
    ./globals.nix
    ./lidarr.nix
    ./postgres.nix
    ./radarr.nix
    ./sonarr.nix
  ];

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

    dirRegistrations = mkOption {
      type = with types;
        listOf (submodule {
          options = {
            dir = mkOption {
              type = path;
              description = "Directory path to create";
            };
            owner = mkOption {
              type = str;
              description = "Owner of the directory";
            };
            group = mkOption {
              type = str;
              description = "Group of the directory";
            };
            mode = mkOption {
              type = str;
              default = "0775";
              description = "Permission mode for the directory";
            };
          };
        });
      default = [];
      description = ''
        Directory registrations from services. Each service can register
        directories it needs to be created.
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

        # Service-registered directories
        ${concatMapStringsSep "\n" (reg: ''
            ${pkgs.coreutils}/bin/mkdir -p ${reg.dir}
            ${pkgs.coreutils}/bin/chown ${reg.owner}:${reg.group} ${reg.dir}
            ${pkgs.coreutils}/bin/chmod ${reg.mode} ${reg.dir}
          '')
          cfg.dirRegistrations}
      '';
    };

    services.nginx = {
      enable = true;

      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      virtualHosts.localhost = {
        serverName = "localhost";
        default = true;
        listen = [
          {
            addr = "0.0.0.0";
            port = 80;
          }
        ];
      };
    };

    server = {
      lidarr.enable = true;
      postgres.enable = true;
      radarr.enable = true;
      sonarr.enable = true;
    };
  };
}
