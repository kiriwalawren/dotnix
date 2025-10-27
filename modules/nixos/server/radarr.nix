{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  inherit (config) server;
  inherit (server) globals;
  cfg = config.server.radarr;
  port = 7878;
  stateDir = "${server.stateDir}/radarr";
  mediaDir = "${server.mediaDir}/movies";
  arrCommon = import ./arr-common.nix {inherit lib pkgs;};
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

    config = mkOption {
      type = arrCommon.arrConfigModule;
      default = {};
      description = ''
        Radarr configuration options that will be set via the API.
      '';
    };
  };

  config = mkIf (server.enable && cfg.enable) {
    # Set defaults for radarr-specific settings
    server.radarr.config = {
      port = mkDefault port;
      branch = mkDefault "master";
      instanceName = mkDefault "Radarr";
      urlBase = mkDefault "/radarr";
      rootFolders = mkDefault [mediaDir];
      apiKeySecret = mkDefault config.sops.secrets."radarr/api_key".path;
      usernameSecret = mkDefault config.sops.secrets."radarr/auth/username".path;
      passwordSecret = mkDefault config.sops.secrets."radarr/auth/password".path;
    };

    # Register directories to be created
    server.dirRegistrations = [
      {
        inherit (globals.radarr) group;
        dir = stateDir;
        owner = globals.radarr.user;
      }
      {
        inherit (globals.radarr) group;
        dir = mediaDir;
        owner = globals.libraryOwner.user;
      }
    ];

    sops.secrets = {
      "radarr/api_key" = {
        inherit (globals.radarr) group;
        owner = globals.radarr.user;
        mode = "0440";
      };
      "radarr/auth/username" = {
        inherit (globals.radarr) group;
        owner = globals.radarr.user;
        mode = "0440";
      };
      "radarr/auth/password" = {
        inherit (globals.radarr) group;
        owner = globals.radarr.user;
        mode = "0440";
      };
    };

    services = {
      radarr = {
        inherit (cfg) enable;
        inherit (globals.radarr) user group;
        dataDir = stateDir;
        settings =
          {
            auth = {
              required = "Enabled";
              method = "Forms";
            };
            server = {
              inherit port;
              inherit (cfg.config) urlBase;
            };
          }
          // optionalAttrs config.services.postgresql.enable {
            postgres = {
              host = "/run/postgresql";
              port = 5432;
              user = "radarr";
              mainDb = "radarr";
            };
          };
      };

      postgresql = mkIf config.services.postgresql.enable {
        ensureDatabases = ["radarr" "radarr_log"];
        ensureUsers = [
          {
            name = "radarr";
            ensureDBOwnership = true;
          }
        ];
      };

      nginx.virtualHosts.localhost.locations."${cfg.config.urlBase}" = {
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

    users = {
      groups.${globals.radarr.group}.gid = globals.gids.${globals.radarr.group};
      users.${globals.radarr.user} = {
        inherit (globals.radarr) group;
        isSystemUser = true;
        uid = globals.uids.${globals.radarr.user};
      };
    };

    systemd.services = {
      # Create environment file setup service
      radarr-env = {
        description = "Setup Radarr environment file";
        wantedBy = ["radarr.service"];
        before = ["radarr.service"];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script = ''
          mkdir -p /run/radarr
          echo "RADARR__AUTH__APIKEY=$(cat ${config.sops.secrets."radarr/api_key".path})" > /run/radarr/env
          chown ${globals.radarr.user}:${globals.radarr.group} /run/radarr/env
          chmod 0400 /run/radarr/env
        '';
      };

      # Ensure radarr starts after directories are created and VPN is up (if enabled)
      radarr = {
        after =
          ["server-setup-dirs.service" "radarr-env.service"]
          ++ (optional config.services.postgresql.enable "postgresql.service")
          ++ (optional config.system.vpn.enable "mullvad-config.service");
        requires =
          ["server-setup-dirs.service" "radarr-env.service"]
          ++ (optional config.services.postgresql.enable "postgresql.service");
        wants = optional config.system.vpn.enable "mullvad-config.service";
        serviceConfig.EnvironmentFile = "/run/radarr/env";
      };

      # Configure Radarr via API
      radarr-config = arrCommon.mkArrConfigService "radarr" cfg.config;
    };
  };
}
