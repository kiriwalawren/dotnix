{
  config,
  lib,
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

    systemd.tmpfiles.rules = [
      "d '${cfg.mediaDir}'  0775 ${globals.libraryOwner.user} ${globals.libraryOwner.group} - -"
    ];

    server.radarr.enable = true;
  };
}
