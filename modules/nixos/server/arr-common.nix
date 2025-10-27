{
  lib,
  pkgs,
  ...
}:
with lib; {
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
        type = types.listOf types.path;
        default = [];
        description = "List of root folders to create";
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

      BASE_URL="http://127.0.0.1:${builtins.toString serviceConfig.port}${serviceConfig.urlBase}"

      # Wait for API to be available (up to 60 seconds)
      echo "Waiting for ${capitalizedName} API to be available..."
      for i in {1..60}; do
        if ${pkgs.curl}/bin/curl -s -f "$BASE_URL/api/v3/system/status?apiKey=$API_KEY" >/dev/null 2>&1; then
          echo "${capitalizedName} API is available"
          break
        fi
        echo "Waiting for ${capitalizedName} API... ($i/60)"
        sleep 1
      done

      # Get current host configuration
      echo "Fetching current host configuration..."
      HOST_CONFIG=$(${pkgs.curl}/bin/curl -s -f -H "X-Api-Key: $API_KEY" "$BASE_URL/api/v3/config/host")

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
          passwordConfirmation: "",
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
        "$BASE_URL/api/v3/config/host/$CONFIG_ID"

      echo "Configuration updated successfully"

      # Create root folders if they don't exist
      echo "Checking for root folders..."
      ROOT_FOLDERS=$(${pkgs.curl}/bin/curl -s -H "X-Api-Key: $API_KEY" "$BASE_URL/api/v3/rootfolder")

      ${concatMapStringsSep "\n" (folder: ''
          if ! echo "$ROOT_FOLDERS" | ${pkgs.jq}/bin/jq -e '.[] | select(.path == "${folder}")' >/dev/null 2>&1; then
            echo "Creating root folder: ${folder}"
            ${pkgs.curl}/bin/curl -s -f -X POST \
              -H "X-Api-Key: $API_KEY" \
              -H "Content-Type: application/json" \
              -d '{"path":"${folder}"}' \
              "$BASE_URL/api/v3/rootfolder"
            echo "Root folder created: ${folder}"
          else
            echo "Root folder already exists: ${folder}"
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
