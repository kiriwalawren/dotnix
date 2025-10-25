{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.server.radarr;
  globals = config.server.globals;
  server = config.server;
  port = 7878;
  stateDir = "${server.stateDir}/radarr";
in {
  options.server.radarr = {
    enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Whether or not to enable the Radarr service.
      '';
    };
  };

  config = mkIf (server.enable && cfg.enable) {
    sops.secrets."radarr/api_key" = {
      owner = globals.radarr.user;
      group = globals.radarr.group;
      mode = "0440";
    };
    sops.secrets."radarr/auth/username" = {
      owner = globals.radarr.user;
      group = globals.radarr.group;
      mode = "0440";
    };
    sops.secrets."radarr/auth/password" = {
      owner = globals.radarr.user;
      group = globals.radarr.group;
      mode = "0440";
    };

    systemd.tmpfiles.rules = [
      "d '${server.mediaDir}/library'        0775 ${globals.libraryOwner.user} ${globals.libraryOwner.group} - -"
      "d '${server.mediaDir}/library/movies' 0775 ${globals.libraryOwner.user} ${globals.libraryOwner.group} - -"
    ];

    users = {
      groups.${globals.radarr.group}.gid = globals.gids.${globals.radarr.group};
      users.${globals.radarr.user} = {
        isSystemUser = true;
        group = globals.radarr.group;
        uid = globals.uids.${globals.radarr.user};
      };
    };

    services.radarr = {
      enable = cfg.enable;
      user = globals.radarr.user;
      group = globals.radarr.group;
      settings.server.port = port;
      dataDir = stateDir;
    };

    # Inject secrets into Radarr config
    systemd.services.radarr-secrets = {
      description = "Inject secrets into Radarr configuration";
      after = ["radarr.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "oneshot";
        User = globals.radarr.user;
        Group = globals.radarr.group;
      };

      script = ''
        set -eu

        configFile="${stateDir}/config.xml"

        # Wait for config file to be created (up to 30 seconds)
        for i in {1..30}; do
          if [ -f "$configFile" ]; then
            break
          fi
          echo "Waiting for Radarr to create config file... ($i/30)"
          sleep 1
        done

        if [ ! -f "$configFile" ]; then
          echo "Config file was not created, exiting"
          exit 1
        fi

        # Read secrets
        API_KEY=$(cat ${config.sops.secrets."radarr/api_key".path})
        AUTH_USER=$(cat ${config.sops.secrets."radarr/auth/username".path})
        AUTH_PASS=$(cat ${config.sops.secrets."radarr/auth/password".path})

        # Update config.xml using xmlstarlet
        ${pkgs.xmlstarlet}/bin/xmlstarlet ed -L \
          -u "//ApiKey" -v "$API_KEY" \
          -u "//AuthenticationMethod" -v "Forms" \
          -u "//AuthenticationRequired" -v "Enabled" \
          -u "//Username" -v "$AUTH_USER" \
          -u "//Password" -v "$AUTH_PASS" \
          -u "//UrlBase" -v "/radarr" \
          "$configFile"

        # Restart radarr to pick up the new config
        systemctl restart radarr.service
      '';
    };

    services.nginx = {
      enable = true;

      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      virtualHosts."localhost" = {
        listen = [
          {
            addr = "0.0.0.0";
            port = 80;
          }
        ];

        serverName = "localhost";
        default = true;

        locations."/radarr" = {
          proxyPass = "http://127.0.0.1:${builtins.toString port}";
          recommendedProxySettings = true;
          extraConfig = ''
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Server $host;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_redirect off;
          '';
        };
      };
    };
  };
}
