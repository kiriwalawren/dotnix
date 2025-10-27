{
  lib,
  pkgs,
  ...
}:
with lib; {
  # Helper function to create a secrets injection service for *arr applications
  mkArrConfigService = {
    serviceName, # e.g., "radarr", "sonarr"
    port,
    stateDir,
    apiKeySecret,
    usernameSecret,
    passwordSecret,
    urlBase,
    rootFolders, # List of paths to create as root folders
    user,
    group,
  }: {
    description = "Inject secrets into ${serviceName} configuration";
    after = ["${serviceName}.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      set -eu

      configFile="${stateDir}/config.xml"

      # Wait for config file to be created (up to 30 seconds)
      for i in {1..30}; do
        if [ -f "$configFile" ]; then
          break
        fi
        echo "Waiting for ${serviceName} to create config file... ($i/30)"
        sleep 1
      done

      if [ ! -f "$configFile" ]; then
        echo "Config file was not created, exiting"
        exit 1
      fi

      # Read secrets
      API_KEY=$(cat ${apiKeySecret})
      AUTH_USER=$(cat ${usernameSecret})

      # Backup config
      cp "$configFile" "$configFile.bak"

      # Helper function to set XML elements (delete existing, then insert)
      set_element() {
        local field=$1
        local value=$2
        # Delete all existing instances of the field
        ${pkgs.xmlstarlet}/bin/xmlstarlet ed -L -d "//Config/$field" "$configFile" || true
        # Insert the new value
        ${pkgs.xmlstarlet}/bin/xmlstarlet ed -L -s "//Config" -t elem -n "$field" -v "$value" "$configFile"
      }

      # Set all fields (Username/Password are NOT stored in config.xml)
      set_element "ApiKey" "$API_KEY"
      set_element "AuthenticationMethod" "Forms"
      set_element "AuthenticationRequired" "Enabled"
      set_element "UrlBase" "${urlBase}"

      # Change ownership back to service user
      chown ${user}:${group} "$configFile"

      # Set username and password in database (using PBKDF2)
      dbFile="${stateDir}/${serviceName}.db"

      # Wait for database and Users table to be created (up to 30 seconds)
      for i in {1..30}; do
        if [ -f "$dbFile" ] && ${pkgs.sqlite}/bin/sqlite3 "$dbFile" "SELECT name FROM sqlite_master WHERE type='table' AND name='Users';" | grep -q Users; then
          break
        fi
        echo "Waiting for ${serviceName} to create Users table... ($i/30)"
        sleep 1
      done

      if ! ${pkgs.sqlite}/bin/sqlite3 "$dbFile" "SELECT name FROM sqlite_master WHERE type='table' AND name='Users';" | grep -q Users; then
        echo "Users table was not created, exiting"
        exit 1
      fi

      # Generate PBKDF2 hash using Python (read password directly from file to avoid shell expansion)
      read SALT HASHED_PASSWORD <<< $(${pkgs.python3}/bin/python3 -c "
      import base64
      import hashlib
      import secrets
      import sys

      # Read password directly from file to avoid bash variable expansion issues
      with open('${passwordSecret}', 'rb') as f:
          password = f.read()

      salt = secrets.token_bytes(16)
      iterations = 10000
      num_bytes = 32

      # PBKDF2-HMAC-SHA512
      hashed = hashlib.pbkdf2_hmac('sha512', password, salt, iterations, dklen=num_bytes)

      print(base64.b64encode(salt).decode(), base64.b64encode(hashed).decode())
      ")

      # Retry database write until it succeeds (database might be locked during initialization)
      for i in {1..60}; do
        if ${pkgs.sqlite}/bin/sqlite3 "$dbFile" "
          DELETE FROM Users;
          INSERT INTO Users (Id, Identifier, Username, Password, Salt, Iterations)
          VALUES (1, lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || substr(hex(randomblob(2)),2) || '-' || substr('89ab',abs(random()) % 4 + 1, 1) || substr(hex(randomblob(2)),2) || '-' || hex(randomblob(6))), '$AUTH_USER', '$HASHED_PASSWORD', '$SALT', 10000);
        " 2>/dev/null; then
          echo "Successfully inserted user credentials"
          break
        fi
        echo "Database locked, retrying... ($i/60)"
        sleep 1
      done

      # Restart service to pick up the new config
      systemctl restart ${serviceName}.service

      # Wait for API to be fully ready after restart
      echo "Waiting for ${serviceName} to be ready..."
      for i in {1..30}; do
        if ${pkgs.curl}/bin/curl -s -f -H "X-Api-Key: $API_KEY" http://127.0.0.1:${builtins.toString port}${urlBase}/api/v3/system/status >/dev/null 2>&1; then
          echo "${serviceName} is ready"
          break
        fi
        echo "Waiting for ${serviceName} API... ($i/30)"
        sleep 2
      done

      # Create root folders if they don't exist
      echo "Checking for root folders..."
      ROOT_FOLDERS=$(${pkgs.curl}/bin/curl -s -H "X-Api-Key: $API_KEY" http://127.0.0.1:${builtins.toString port}${urlBase}/api/v3/rootfolder)

      ${concatMapStringsSep "\n" (folder: ''
          if ! echo "$ROOT_FOLDERS" | ${pkgs.jq}/bin/jq -e '.[] | select(.path == "${folder}")' >/dev/null 2>&1; then
            echo "Creating root folder: ${folder}"
            ${pkgs.curl}/bin/curl -s -X POST \
              -H "X-Api-Key: $API_KEY" \
              -H "Content-Type: application/json" \
              -d '{"path":"${folder}"}' \
              http://127.0.0.1:${builtins.toString port}${urlBase}/api/v3/rootfolder
            echo "Root folder created: ${folder}"
          else
            echo "Root folder already exists: ${folder}"
          fi
        '')
        rootFolders}
    '';
  };
}
