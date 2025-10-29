{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  arrConfigModule = import ./configModule.nix {inherit lib;};
  mkArrHostConfigService = import ./hostConfigService.nix {inherit lib pkgs;};
  mkArrRootFoldersService = import ./rootFoldersService.nix {inherit lib pkgs;};
in {
  # Helper function to create a complete *arr NixOS module
  # This reduces boilerplate across sonarr/radarr/lidarr modules
  mkArrModule = {
    serviceName, # e.g., "sonarr", "radarr", "lidarr"
    port,
    defaultBranch,
    defaultApiVersion ? "v3",
    mediaDirs ? [], # list of {dir, owner} attribute sets
    rootFolders ? [], # default rootFolders configuration
    usesDynamicUser ? false, # whether the service uses systemd DynamicUser
  }: let
    inherit (config) server;
    inherit (server) globals;
    cfg = config.server.${serviceName};
    stateDir = "${server.stateDir}/${serviceName}";
    capitalizedName = toUpper (substring 0 1 serviceName) + substring 1 (-1) serviceName;
    globalsCfg = globals.${serviceName};
  in {
    options.server.${serviceName} = {
      enable = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = "Whether or not to enable the ${capitalizedName} service.";
      };

      config = mkOption {
        type = arrConfigModule;
        default = {};
        description = "${capitalizedName} configuration options that will be set via the API.";
      };
    };

    config = mkIf (server.enable && cfg.enable) {
      # Set defaults for service-specific settings
      server.${serviceName}.config = {
        inherit port;
        branch = mkDefault defaultBranch;
        instanceName = mkDefault capitalizedName;
        urlBase = mkDefault "/${serviceName}";
        apiVersion = mkDefault defaultApiVersion;
        rootFolders = mkDefault rootFolders;
        apiKeySecret = mkDefault config.sops.secrets."${serviceName}/api_key".path;
        usernameSecret = mkDefault config.sops.secrets."${serviceName}/auth/username".path;
        passwordSecret = mkDefault config.sops.secrets."${serviceName}/auth/password".path;
      };

      # Register directories to be created
      server.dirRegistrations =
        [
          (
            if usesDynamicUser
            then {
              dir = stateDir;
              owner = "root";
              group = "root";
              mode = "0700";
            }
            else {
              inherit (globalsCfg) group;
              dir = stateDir;
              owner = globalsCfg.user;
            }
          )
        ]
        ++ (map (mediaDir: {
            inherit (globalsCfg) group;
            inherit (mediaDir) dir owner;
          })
          mediaDirs);

      sops.secrets = {
        "${serviceName}/api_key" = {
          inherit (globalsCfg) group;
          owner = globalsCfg.user;
          mode = "0440";
        };
        "${serviceName}/auth/username" = {
          inherit (globalsCfg) group;
          owner = globalsCfg.user;
          mode = "0440";
        };
        "${serviceName}/auth/password" = {
          inherit (globalsCfg) group;
          owner = globalsCfg.user;
          mode = "0440";
        };
      };

      services = {
        ${serviceName} =
          {
            inherit (cfg) enable;
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
                  inherit (globalsCfg) user;
                  host = "/run/postgresql";
                  port = 5432;
                  mainDb = serviceName;
                  logDb = serviceName;
                };
              };
          }
          // optionalAttrs (!usesDynamicUser) {
            inherit (globalsCfg) user group;
          };

        postgresql = mkIf config.services.postgresql.enable {
          ensureDatabases = [serviceName];
          ensureUsers = [
            {
              name = globalsCfg.user;
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

      users = mkIf (!usesDynamicUser) {
        groups.${globalsCfg.group}.gid = globals.gids.${globalsCfg.group};
        users.${globalsCfg.user} = {
          inherit (globalsCfg) group;
          isSystemUser = true;
          uid = globals.uids.${globalsCfg.user};
        };
      };

      systemd.services =
        {
          # Create environment file setup service
          "${serviceName}-env" = {
            description = "Setup ${capitalizedName} environment file";
            wantedBy = ["${serviceName}.service"];
            before = ["${serviceName}.service"];

            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };

            script = let
              envVar = toUpper serviceName + "__AUTH__APIKEY";
            in ''
              mkdir -p /run/${serviceName}
              echo "${envVar}=$(cat ${config.sops.secrets."${serviceName}/api_key".path})" > /run/${serviceName}/env
              chown ${globalsCfg.user}:${globalsCfg.group} /run/${serviceName}/env
              chmod 0400 /run/${serviceName}/env
            '';
          };

          # Ensure main service (radarr.service, etc.) service starts after
          # directories are created and VPN is up (if enabled)
          ${serviceName} = {
            after =
              ["server-setup-dirs.service" "${serviceName}-env.service"]
              ++ (optional config.services.postgresql.enable "postgresql.service")
              ++ (optional config.system.vpn.enable "mullvad-config.service");
            requires =
              ["server-setup-dirs.service" "${serviceName}-env.service"]
              ++ (optional config.services.postgresql.enable "postgresql.service");
            wants = optional config.system.vpn.enable "mullvad-config.service";
            serviceConfig.EnvironmentFile = "/run/${serviceName}/env";
          };

          # Configure service via API
          "${serviceName}-config" = mkArrHostConfigService serviceName cfg.config;
        }
        # Only create root folders service if rootFolders is not empty
        // optionalAttrs (cfg.config.rootFolders != []) {
          "${serviceName}-rootfolders" = mkArrRootFoldersService serviceName cfg.config;
        };
    };
  };
}
