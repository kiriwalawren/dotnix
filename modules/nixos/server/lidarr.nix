{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  inherit (config) server;
  inherit (server) globals;
  cfg = config.server.lidarr;
  port = 8686;
  stateDir = "${server.stateDir}/lidarr";
  mediaDir = "${server.mediaDir}/music";
  arrCommon = import ./arr-common.nix {inherit lib pkgs;};
in {
  options.server.lidarr = {
    enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Whether or not to enable the Lidarr service.
      '';
    };

    config = mkOption {
      type = arrCommon.arrConfigModule;
      default = {};
      description = ''
        Lidarr configuration options that will be set via the API.
      '';
    };
  };

  config = mkIf (server.enable && cfg.enable) {
    # Set defaults for lidarr-specific settings
    server.lidarr.config = {
      port = mkDefault port;
      branch = mkDefault "master";
      instanceName = mkDefault "Lidarr";
      urlBase = mkDefault "/lidarr";
      apiVersion = mkDefault "v1";
      rootFolders = mkDefault [mediaDir];
      apiKeySecret = mkDefault config.sops.secrets."lidarr/api_key".path;
      usernameSecret = mkDefault config.sops.secrets."lidarr/auth/username".path;
      passwordSecret = mkDefault config.sops.secrets."lidarr/auth/password".path;
    };

    # Register directories to be created
    server.dirRegistrations = [
      {
        inherit (globals.lidarr) group;
        dir = stateDir;
        owner = globals.lidarr.user;
      }
      {
        inherit (globals.lidarr) group;
        dir = mediaDir;
        owner = globals.libraryOwner.user;
      }
    ];

    sops.secrets = {
      "lidarr/api_key" = {
        inherit (globals.lidarr) group;
        owner = globals.lidarr.user;
        mode = "0440";
      };
      "lidarr/auth/username" = {
        inherit (globals.lidarr) group;
        owner = globals.lidarr.user;
        mode = "0440";
      };
      "lidarr/auth/password" = {
        inherit (globals.lidarr) group;
        owner = globals.lidarr.user;
        mode = "0440";
      };
    };

    services = {
      lidarr = {
        inherit (cfg) enable;
        inherit (globals.lidarr) user group;
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
              user = "lidarr";
              mainDb = "lidarr";
              logDb = "lidarr";
            };
          };
      };

      postgresql = mkIf config.services.postgresql.enable {
        ensureDatabases = ["lidarr"];
        ensureUsers = [
          {
            name = "lidarr";
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
      groups.${globals.lidarr.group}.gid = globals.gids.${globals.lidarr.group};
      users.${globals.lidarr.user} = {
        inherit (globals.lidarr) group;
        isSystemUser = true;
        uid = globals.uids.${globals.lidarr.user};
      };
    };

    systemd.services = {
      # Create environment file setup service
      lidarr-env = {
        description = "Setup Lidarr environment file";
        wantedBy = ["lidarr.service"];
        before = ["lidarr.service"];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script = ''
          mkdir -p /run/lidarr
          echo "LIDARR__AUTH__APIKEY=$(cat ${config.sops.secrets."lidarr/api_key".path})" > /run/lidarr/env
          chown ${globals.lidarr.user}:${globals.lidarr.group} /run/lidarr/env
          chmod 0400 /run/lidarr/env
        '';
      };

      # Ensure lidarr starts after directories are created and VPN is up (if enabled)
      lidarr = {
        after =
          ["server-setup-dirs.service" "lidarr-env.service"]
          ++ (optional config.services.postgresql.enable "postgresql.service")
          ++ (optional config.system.vpn.enable "mullvad-config.service");
        requires =
          ["server-setup-dirs.service" "lidarr-env.service"]
          ++ (optional config.services.postgresql.enable "postgresql.service");
        wants = optional config.system.vpn.enable "mullvad-config.service";
        serviceConfig.EnvironmentFile = "/run/lidarr/env";
      };

      # Configure Lidarr via API
      lidarr-config = arrCommon.mkArrConfigService "lidarr" cfg.config;
    };
  };
}
