{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  # Helper function to create a complete *arr NixOS module
  # This reduces boilerplate across sonarr/radarr/lidarr modules
  mkArrModule = {
    serviceName, # e.g., "sonarr", "radarr", "lidarr"
    port,
    defaultBranch,
    defaultApiVersion ? "v3",
    mediaDirs, # list of {dir, owner} attribute sets
    defaultRootFolders, # default rootFolders configuration
  }: let
    inherit (config) server;
    inherit (server) globals;
    cfg = config.server.${serviceName};
    stateDir = "${server.stateDir}/${serviceName}";
    arrCommon = import ./arr-common.nix {inherit config lib pkgs;};
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
        type = arrCommon.arrConfigModule;
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
        rootFolders = mkDefault defaultRootFolders;
        apiKeySecret = mkDefault config.sops.secrets."${serviceName}/api_key".path;
        usernameSecret = mkDefault config.sops.secrets."${serviceName}/auth/username".path;
        passwordSecret = mkDefault config.sops.secrets."${serviceName}/auth/password".path;
      };

      # Register directories to be created
      server.dirRegistrations =
        [
          {
            inherit (globalsCfg) group;
            dir = stateDir;
            owner = globalsCfg.user;
          }
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
        ${serviceName} = {
          inherit (cfg) enable;
          inherit (globalsCfg) user group;
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
                user = serviceName;
                mainDb = serviceName;
                logDb = serviceName;
              };
            };
        };

        postgresql = mkIf config.services.postgresql.enable {
          ensureDatabases = [serviceName];
          ensureUsers = [
            {
              name = serviceName;
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
        groups.${globalsCfg.group}.gid = globals.gids.${globalsCfg.group};
        users.${globalsCfg.user} = {
          inherit (globalsCfg) group;
          isSystemUser = true;
          uid = globals.uids.${globalsCfg.user};
        };
      };

      systemd.services = {
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
        "${serviceName}-config" = arrCommon.mkArrConfigService serviceName cfg.config;
      };
    };
  };

  # Shared configuration submodule for *arr applications
  arrConfigModule = types.submodule {
    options = {
      # Connection settings
      bindAddress = mkOption {
        type = types.str;
        default = "*";
        description = "Address to bind to";
      };

      port = mkOption {
        type = types.port;
        description = "Port the service listens on";
      };

      sslPort = mkOption {
        type = types.port;
        default = 9898;
        description = "SSL port";
      };

      enableSsl = mkOption {
        type = types.bool;
        default = false;
        description = "Enable SSL";
      };

      # Authentication settings
      authenticationMethod = mkOption {
        type = types.enum ["none" "basic" "forms" "external"];
        default = "forms";
        description = "Authentication method";
      };

      authenticationRequired = mkOption {
        type = types.enum ["enabled" "disabled" "disabledForLocalAddresses"];
        default = "enabled";
        description = "Authentication requirement level";
      };

      apiKeySecret = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to API key secret file";
      };

      usernameSecret = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to username secret file";
      };

      passwordSecret = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to password secret file";
      };

      # URL settings
      urlBase = mkOption {
        type = types.str;
        default = "";
        description = "URL base path";
      };

      apiVersion = mkOption {
        type = types.str;
        default = "v3";
        description = "Current version of the API of the select service";
      };

      applicationUrl = mkOption {
        type = types.str;
        default = "";
        description = "Application URL";
      };

      instanceName = mkOption {
        type = types.str;
        description = "Instance name";
      };

      # Logging settings
      logLevel = mkOption {
        type = types.enum ["info" "debug" "trace"];
        default = "info";
        description = "Log level";
      };

      logSizeLimit = mkOption {
        type = types.int;
        default = 1;
        description = "Log size limit in MB";
      };

      consoleLogLevel = mkOption {
        type = types.str;
        default = "";
        description = "Console log level";
      };

      # Update settings
      branch = mkOption {
        type = types.str;
        description = "Update branch";
      };

      updateAutomatically = mkOption {
        type = types.bool;
        default = false;
        description = "Update automatically";
      };

      updateMechanism = mkOption {
        type = types.enum ["builtIn" "script" "external" "docker"];
        default = "builtIn";
        description = "Update mechanism";
      };

      updateScriptPath = mkOption {
        type = types.str;
        default = "";
        description = "Update script path";
      };

      # Proxy settings
      proxyEnabled = mkOption {
        type = types.bool;
        default = false;
        description = "Enable proxy";
      };

      proxyType = mkOption {
        type = types.enum ["http" "socks4" "socks5"];
        default = "http";
        description = "Proxy type";
      };

      proxyHostname = mkOption {
        type = types.str;
        default = "";
        description = "Proxy hostname";
      };

      proxyPort = mkOption {
        type = types.port;
        default = 8080;
        description = "Proxy port";
      };

      proxyUsername = mkOption {
        type = types.str;
        default = "";
        description = "Proxy username";
      };

      proxyPassword = mkOption {
        type = types.str;
        default = "";
        description = "Proxy password";
      };

      proxyBypassFilter = mkOption {
        type = types.str;
        default = "";
        description = "Proxy bypass filter";
      };

      proxyBypassLocalAddresses = mkOption {
        type = types.bool;
        default = true;
        description = "Proxy bypass local addresses";
      };

      # SSL settings
      sslCertPath = mkOption {
        type = types.str;
        default = "";
        description = "SSL certificate path";
      };

      sslCertPassword = mkOption {
        type = types.str;
        default = "";
        description = "SSL certificate password";
      };

      certificateValidation = mkOption {
        type = types.enum ["enabled" "disabled" "disabledForLocalAddresses"];
        default = "enabled";
        description = "Certificate validation";
      };

      # Backup settings
      backupFolder = mkOption {
        type = types.str;
        default = "Backups";
        description = "Backup folder name";
      };

      backupInterval = mkOption {
        type = types.int;
        default = 7;
        description = "Backup interval in days";
      };

      backupRetention = mkOption {
        type = types.int;
        default = 28;
        description = "Backup retention in days";
      };

      # Other settings
      launchBrowser = mkOption {
        type = types.bool;
        default = false;
        description = "Launch browser on start (not applicable for NixOS services)";
      };

      analyticsEnabled = mkOption {
        type = types.bool;
        default = false;
        description = "Enable analytics";
      };

      trustCgnatIpAddresses = mkOption {
        type = types.bool;
        default = false;
        description = "Trust CGNAT IP addresses";
      };

      # Root folders (managed via separate API endpoint)
      rootFolders = mkOption {
        type = types.listOf types.attrs;
        default = [];
        description = ''
          List of root folders to create. Each folder is an attribute set that will be
          converted to JSON and sent to the API.

          For Sonarr/Radarr, a simple path is sufficient: {path = "/path/to/folder";}
          For Lidarr, additional fields are required like defaultQualityProfileId, etc.
        '';
      };
    };
  };

  # Helper function to create a systemd service that configures *arr via API
  mkArrConfigService = serviceName: serviceConfig: {
    description = "Configure ${serviceName} via API";
    after = ["${serviceName}.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = let
      capitalizedName = lib.toUpper (builtins.substring 0 1 serviceName) + builtins.substring 1 (-1) serviceName;
    in ''
      set -eu

      # Read secrets
      API_KEY=$(cat ${serviceConfig.apiKeySecret})
      AUTH_USER=$(cat ${serviceConfig.usernameSecret})
      AUTH_PASSWORD=$(cat ${serviceConfig.passwordSecret})

      BASE_URL="http://127.0.0.1:${builtins.toString serviceConfig.port}${serviceConfig.urlBase}/api/${serviceConfig.apiVersion}"

      # Wait for API to be available (up to 60 seconds)
      echo "Waiting for ${capitalizedName} API to be available..."
      for i in {1..60}; do
        if ${pkgs.curl}/bin/curl -s -f "$BASE_URL/system/status?apiKey=$API_KEY" >/dev/null 2>&1; then
          echo "${capitalizedName} API is available"
          break
        fi
        echo "Waiting for ${capitalizedName} API... ($i/60)"
        sleep 1
      done

      # Get current host configuration
      echo "Fetching current host configuration..."
      HOST_CONFIG=$(${pkgs.curl}/bin/curl -s -f -H "X-Api-Key: $API_KEY" "$BASE_URL/config/host")

      if [ -z "$HOST_CONFIG" ]; then
        echo "Failed to fetch host configuration"
        exit 1
      fi

      # Extract the ID from the host config (needed for PUT request)
      CONFIG_ID=$(echo "$HOST_CONFIG" | ${pkgs.jq}/bin/jq -r '.id')

      # Build the complete configuration JSON
      echo "Building configuration..."
      NEW_CONFIG=$(${pkgs.jq}/bin/jq -n \
        --arg apiKey "$API_KEY" \
        --arg username "$AUTH_USER" \
        --arg password "$AUTH_PASSWORD" \
        --argjson id "$CONFIG_ID" \
        '{
          id: $id,
          bindAddress: "${serviceConfig.bindAddress}",
          port: ${builtins.toString serviceConfig.port},
          sslPort: ${builtins.toString serviceConfig.sslPort},
          enableSsl: ${boolToString serviceConfig.enableSsl},
          launchBrowser: ${boolToString serviceConfig.launchBrowser},
          authenticationMethod: "${serviceConfig.authenticationMethod}",
          authenticationRequired: "${serviceConfig.authenticationRequired}",
          analyticsEnabled: ${boolToString serviceConfig.analyticsEnabled},
          username: $username,
          password: $password,
          passwordConfirmation: $password,
          logLevel: "${serviceConfig.logLevel}",
          logSizeLimit: ${builtins.toString serviceConfig.logSizeLimit},
          consoleLogLevel: "${serviceConfig.consoleLogLevel}",
          branch: "${serviceConfig.branch}",
          apiKey: $apiKey,
          sslCertPath: "${serviceConfig.sslCertPath}",
          sslCertPassword: "${serviceConfig.sslCertPassword}",
          urlBase: "${serviceConfig.urlBase}",
          instanceName: "${serviceConfig.instanceName}",
          applicationUrl: "${serviceConfig.applicationUrl}",
          updateAutomatically: ${boolToString serviceConfig.updateAutomatically},
          updateMechanism: "${serviceConfig.updateMechanism}",
          updateScriptPath: "${serviceConfig.updateScriptPath}",
          proxyEnabled: ${boolToString serviceConfig.proxyEnabled},
          proxyType: "${serviceConfig.proxyType}",
          proxyHostname: "${serviceConfig.proxyHostname}",
          proxyPort: ${builtins.toString serviceConfig.proxyPort},
          proxyUsername: "${serviceConfig.proxyUsername}",
          proxyPassword: "${serviceConfig.proxyPassword}",
          proxyBypassFilter: "${serviceConfig.proxyBypassFilter}",
          proxyBypassLocalAddresses: ${boolToString serviceConfig.proxyBypassLocalAddresses},
          certificateValidation: "${serviceConfig.certificateValidation}",
          backupFolder: "${serviceConfig.backupFolder}",
          backupInterval: ${builtins.toString serviceConfig.backupInterval},
          backupRetention: ${builtins.toString serviceConfig.backupRetention},
          trustCgnatIpAddresses: ${boolToString serviceConfig.trustCgnatIpAddresses}
        }')

      # Update host configuration
      echo "Updating ${capitalizedName} configuration via API..."
      ${pkgs.curl}/bin/curl -s -f -X PUT \
        -H "X-Api-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$NEW_CONFIG" \
        "$BASE_URL/config/host/$CONFIG_ID"

      echo "Configuration updated successfully"

      # Create root folders if they don't exist
      echo "Checking for root folders..."
      ROOT_FOLDERS=$(${pkgs.curl}/bin/curl -s -H "X-Api-Key: $API_KEY" "$BASE_URL/rootfolder")

      ${concatMapStringsSep "\n" (folderConfig: let
          # Convert the Nix attr set to a JSON string
          folderJson = builtins.toJSON folderConfig;
          # Extract the path for checking existence
          folderPath = folderConfig.path;
        in ''
          if ! echo "$ROOT_FOLDERS" | ${pkgs.jq}/bin/jq -e '.[] | select(.path == "${folderPath}")' >/dev/null 2>&1; then
            echo "Creating root folder: ${folderPath}"
            ${pkgs.curl}/bin/curl -s -f -X POST \
              -H "X-Api-Key: $API_KEY" \
              -H "Content-Type: application/json" \
              -d '${folderJson}' \
              "$BASE_URL/rootfolder"
            echo "Root folder created: ${folderPath}"
          else
            echo "Root folder already exists: ${folderPath}"
          fi
        '')
        serviceConfig.rootFolders}

      echo "${capitalizedName} configuration complete"

      # Restart the service to pick up the new configuration
      echo "Restarting ${serviceName} service..."
      systemctl restart ${serviceName}.service
      echo "${capitalizedName} service restarted"
    '';
  };
}
