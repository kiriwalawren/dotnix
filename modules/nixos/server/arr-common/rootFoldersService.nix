{
  lib,
  pkgs,
}:
# Helper function to create a systemd service that configures *arr root folders via API
serviceName: serviceConfig:
with lib; {
  description = "Configure ${serviceName} root folders via API";
  after = ["${serviceName}-config.service"];
  wantedBy = ["multi-user.target"];

  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
  };

  script = let
    capitalizedName = lib.toUpper (builtins.substring 0 1 serviceName) + builtins.substring 1 (-1) serviceName;
  in ''
    set -eu

    # Read API key secret
    API_KEY=$(cat ${serviceConfig.apiKeySecret})

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

    echo "${capitalizedName} root folders configuration complete"
  '';
}
