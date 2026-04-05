{
  flake.modules.homeManager.gui =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.services.immich-upload;
    in
    {
      options.services.immich-upload = {
        serverUrl = lib.mkOption {
          type = lib.types.str;
          default = "http://photos.homelab";
          description = "Immich server URL";
        };

        uploadPaths = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ "${config.home.homeDirectory}/Photos" ];
          description = "List of paths to upload to Immich";
        };
      };

      config = {
        sops.secrets."immich/uploads-api-key" = { };

        home.file."Photos/.keep".text = "";

        systemd.user.services.immich-upload = {
          Unit = {
            Description = "Upload photos to Immich";
            After = [ "network.target" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "immich-upload" ''
              API_KEY=$(cat ${config.sops.secrets."immich/uploads-api-key".path})
              ${pkgs.immich-cli}/bin/immich \
                --url ${cfg.serverUrl} \
                --key "$API_KEY" \
                upload --recursive \
                ${lib.escapeShellArgs cfg.uploadPaths}
            '';
          };
        };

        systemd.user.timers.immich-upload = {
          Unit.Description = "Upload photos to Immich every 30 minutes";
          Timer = {
            OnBootSec = "5m";
            OnUnitActiveSec = "30m";
            Unit = "immich-upload.service";
          };
          Install.WantedBy = [ "timers.target" ];
        };
      };
    };
}
