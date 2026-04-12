{
  flake.modules.nixos.base =
    {
      lib,
      ...
    }:
    {
      options.system.backup = {
        paths = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
          description = "Paths to backup.";
        };

        exclude = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
          description = "Paths to exclude from backup.";
        };
      };
    };

  flake.modules.nixos.backup =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.system.backup;
      resticWrapper = pkgs.writeShellScriptBin "restic" ''
        export AWS_ACCESS_KEY_ID="$(cat ${config.sops.secrets."backblaze/kiriwalawren/key-id".path})"
        export AWS_SECRET_ACCESS_KEY="$(cat ${
          config.sops.secrets."backblaze/kiriwalawren/application-key".path
        })"
        export RESTIC_PASSWORD="$(cat ${config.sops.secrets."restic/encryption-key".path})"
        export RESTIC_REPOSITORY="s3:https://s3.us-east-005.backblazeb2.com/kiriwalawren/$(hostname)"
        exec ${pkgs.restic}/bin/restic "$@"
      '';
    in
    {
      config = lib.mkIf (cfg.paths != [ ]) {
        environment.systemPackages = [ resticWrapper ];
        sops.secrets."backblaze/kiriwalawren/key-id" = { };
        sops.secrets."backblaze/kiriwalawren/application-key" = { };
        sops.secrets."restic/encryption-key" = { };
        sops.secrets."healthchecks/ping-key" = { };
        sops.templates."restic.env".content = ''
          AWS_ACCESS_KEY_ID=${config.sops.placeholder."backblaze/kiriwalawren/key-id"}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."backblaze/kiriwalawren/application-key"}
        '';

        services.restic.backups = {
          ${config.networking.hostName} = {
            inherit (cfg) paths exclude;
            initialize = true;
            repository = "s3:https://s3.us-east-005.backblazeb2.com/kiriwalawren/${config.networking.hostName}";
            passwordFile = config.sops.secrets."restic/encryption-key".path;
            environmentFile = config.sops.templates."restic.env".path;
            timerConfig = {
              OnCalendar = "daily";
              Persistent = true;
            };
            pruneOpts = [
              "--keep-daily 7"
              "--keep-weekly 4"
              "--keep-monthly 6"
            ];
            checkOpts = [
              "--read-data-subset=10%"
            ];
            backupCleanupCommand = ''
              ${pkgs.curl}/bin/curl -fsS --retry 3 https://hc-ping.com/$(cat ${
                config.sops.secrets."healthchecks/ping-key".path
              })/${config.networking.hostName}-backup
            '';
          };
        };

        systemd.services."restic-backups-${config.networking.hostName}" = {
          onSuccess = [ "restic-backup-ping-healthchecks.service" ];
        };

        systemd.services."restic-backup-ping-healthchecks" = {
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "restic-backup-ping-healthchecks" ''
              ${pkgs.curl}/bin/curl -fsS --retry 3 https://hc-ping.com/$(cat ${
                config.sops.secrets."healthchecks/ping-key".path
              })/${config.networking.hostName}-backup
            '';
          };
        };
      };
    };
}
