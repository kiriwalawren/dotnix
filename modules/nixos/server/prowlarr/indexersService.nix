{
  lib,
  pkgs,
}:
# Helper function to create a systemd service that configures Prowlarr indexers via API
serviceName: serviceConfig:
with lib; {
  description = "Configure ${serviceName} indexers via API";
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
    API_KEY=$(cat ${serviceConfig.apiKeyPath})

    BASE_URL="http://127.0.0.1:${builtins.toString serviceConfig.hostConfig.port}${serviceConfig.hostConfig.urlBase}/api/${serviceConfig.apiVersion}"

    # Wait for API to be available (up to 60 seconds)
    echo "Waiting for ${capitalizedName} API to be available..."
    for i in {1..60}; do
      if ${pkgs.curl}/bin/curl -sSf "$BASE_URL/system/status?apiKey=$API_KEY" >/dev/null 2>&1; then
        echo "${capitalizedName} API is available"
        break
      fi
      echo "Waiting for ${capitalizedName} API... ($i/60)"
      sleep 1
    done

    # Fetch all indexer schemas
    echo "Fetching indexer schemas..."
    SCHEMAS=$(${pkgs.curl}/bin/curl -sS -H "X-Api-Key: $API_KEY" "$BASE_URL/indexer/schema")

    # Fetch existing indexers
    echo "Fetching existing indexers..."
    INDEXERS=$(${pkgs.curl}/bin/curl -sS -H "X-Api-Key: $API_KEY" "$BASE_URL/indexer")

    # Build list of configured indexer names
    CONFIGURED_NAMES=$(cat <<'EOF'
    ${builtins.toJSON (map (i: i.name) serviceConfig.indexers)}
    EOF
    )

    # Delete indexers that are not in the configuration
    echo "Removing indexers not in configuration..."
    echo "$INDEXERS" | ${pkgs.jq}/bin/jq -r '.[] | @json' | while IFS= read -r indexer; do
      INDEXER_NAME=$(echo "$indexer" | ${pkgs.jq}/bin/jq -r '.name')
      INDEXER_ID=$(echo "$indexer" | ${pkgs.jq}/bin/jq -r '.id')

      if ! echo "$CONFIGURED_NAMES" | ${pkgs.jq}/bin/jq -e --arg name "$INDEXER_NAME" 'index($name)' >/dev/null 2>&1; then
        echo "Deleting indexer not in config: $INDEXER_NAME (ID: $INDEXER_ID)"
        ${pkgs.curl}/bin/curl -sSf -X DELETE \
          -H "X-Api-Key: $API_KEY" \
          "$BASE_URL/indexer/$INDEXER_ID" >/dev/null || echo "Warning: Failed to delete indexer $INDEXER_NAME"
      fi
    done

    ${concatMapStringsSep "\n" (indexerConfig: let
        indexerName = indexerConfig.name;
        inherit (indexerConfig) apiKeyPath;
        # Extract all attributes except name and apiKeyPath to use as field values
        fieldOverrides = builtins.removeAttrs indexerConfig ["name" "apiKeyPath"];
        # Convert to JSON for passing to the script
        fieldOverridesJson = builtins.toJSON fieldOverrides;
      in ''
        echo "Processing indexer: ${indexerName}"

        # Function to apply field overrides to an indexer JSON object
        apply_field_overrides() {
          local indexer_json="$1"
          local api_key="$2"
          local overrides="$3"

          echo "$indexer_json" | ${pkgs.jq}/bin/jq \
            --arg apiKey "$api_key" \
            --argjson overrides "$overrides" '
              # First set the apiKey field
              .fields[] |= (if .name == "apiKey" then .value = $apiKey else . end)
              # Then apply top-level overrides (like appProfileId)
              | . + $overrides
              # Finally apply field-level overrides
              | .fields[] |= (
                  . as $field |
                  if $overrides[$field.name] != null then
                    .value = $overrides[$field.name]
                  else
                    .
                  end
                )
            '
        }

        # Read the indexer API key from the secret file
        INDEXER_API_KEY=$(cat ${apiKeyPath})

        # Parse field overrides from Nix config
        FIELD_OVERRIDES='${fieldOverridesJson}'

        # Check if indexer already exists
        EXISTING_INDEXER=$(echo "$INDEXERS" | ${pkgs.jq}/bin/jq -r '.[] | select(.name == "${indexerName}") | @json' || echo "")

        if [ -n "$EXISTING_INDEXER" ]; then
          echo "Indexer ${indexerName} already exists, updating..."
          INDEXER_ID=$(echo "$EXISTING_INDEXER" | ${pkgs.jq}/bin/jq -r '.id')

          # Apply field overrides to existing indexer
          UPDATED_INDEXER=$(apply_field_overrides "$EXISTING_INDEXER" "$INDEXER_API_KEY" "$FIELD_OVERRIDES")

          echo "DEBUG: Applied field overrides: $FIELD_OVERRIDES"

          # Update the indexer
          ${pkgs.curl}/bin/curl -sSf -X PUT \
            -H "X-Api-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$UPDATED_INDEXER" \
            "$BASE_URL/indexer/$INDEXER_ID" >/dev/null

          echo "Indexer ${indexerName} updated"
        else
          echo "Indexer ${indexerName} does not exist, creating..."

          # Find the matching schema
          SCHEMA=$(echo "$SCHEMAS" | ${pkgs.jq}/bin/jq -r '.[] | select(.name == "${indexerName}") | @json' || echo "")

          if [ -z "$SCHEMA" ]; then
            echo "Error: No schema found for indexer ${indexerName}"
            exit 1
          fi

          # Apply field overrides to schema
          NEW_INDEXER=$(apply_field_overrides "$SCHEMA" "$INDEXER_API_KEY" "$FIELD_OVERRIDES")

          echo "DEBUG: Applied field overrides: $FIELD_OVERRIDES"
          echo "DEBUG: Indexer JSON payload:"
          echo "$NEW_INDEXER" | ${pkgs.jq}/bin/jq '.'

          # Create the indexer
          ${pkgs.curl}/bin/curl -sSf -X POST \
            -H "X-Api-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$NEW_INDEXER" \
            "$BASE_URL/indexer"

          echo "Indexer ${indexerName} created"
        fi
      '')
      serviceConfig.indexers}

    echo "${capitalizedName} indexers configuration complete"
  '';
}
