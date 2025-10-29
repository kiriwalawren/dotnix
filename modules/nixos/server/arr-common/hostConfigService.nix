{
  lib,
  pkgs,
}:
# Helper function to create a systemd service that configures *arr basic settings via API
serviceName: serviceConfig:
with lib; {
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

    # Restart the service to pick up the new configuration
    echo "Restarting ${serviceName} service..."
    systemctl restart ${serviceName}.service
    echo "${capitalizedName} service restarted"
  '';
}
