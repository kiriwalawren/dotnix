{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  inherit (config) server;
  inherit (server) globals;
  cfg = config.server.sonarr;
  port = 8989;
  stateDir = "${server.stateDir}/sonarr";
  tvDir = "${server.mediaDir}/tv";
  animeDir = "${server.mediaDir}/anime";
in {
  options.server.sonarr = {
    enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Whether or not to enable the Sonarr service.
      '';
    };
  };

  config = mkIf (server.enable && cfg.enable) {
    # Register directories to be created
    server.dirRegistrations = [
      {
        inherit (globals.sonarr) group;
        dir = stateDir;
        owner = globals.sonarr.user;
      }
      {
        inherit (globals.sonarr) group;
        dir = tvDir;
        owner = globals.libraryOwner.user;
      }
      {
        inherit (globals.sonarr) group;
        dir = animeDir;
        owner = globals.libraryOwner.user;
      }
    ];

    sops.secrets = {
      "sonarr/api_key" = {
        inherit (globals.sonarr) group;
        owner = globals.sonarr.user;
        mode = "0440";
      };
      "sonarr/auth/username" = {
        inherit (globals.sonarr) group;
        owner = globals.sonarr.user;
        mode = "0440";
      };
      "sonarr/auth/password" = {
        inherit (globals.sonarr) group;
        owner = globals.sonarr.user;
        mode = "0440";
      };
    };

    users = {
      groups.${globals.sonarr.group}.gid = globals.gids.${globals.sonarr.group};
      users.${globals.sonarr.user} = {
        inherit (globals.sonarr) group;
        isSystemUser = true;
        uid = globals.uids.${globals.sonarr.user};
      };
    };

    services.sonarr = {
      inherit (cfg) enable;
      inherit (globals.sonarr) user group;
      dataDir = stateDir;
    };

    # Ensure sonarr starts after directories are created and VPN is up (if enabled)
    systemd.services.sonarr = {
      after = ["server-setup-dirs.service"] ++ (optional config.system.vpn.enable "mullvad-config.service");
      requires = ["server-setup-dirs.service"];
      wants = optional config.system.vpn.enable "mullvad-config.service";
    };

    # Inject secrets into Sonarr config
    systemd.services.sonarr-secrets = {
      description = "Inject secrets into Sonarr configuration";
      after = ["sonarr.service"];
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
          echo "Waiting for Sonarr to create config file... ($i/30)"
          sleep 1
        done

        if [ ! -f "$configFile" ]; then
          echo "Config file was not created, exiting"
          exit 1
        fi

        # Read secrets
        API_KEY=$(cat ${config.sops.secrets."sonarr/api_key".path})
        AUTH_USER=$(cat ${config.sops.secrets."sonarr/auth/username".path})

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
        set_element "UrlBase" "/sonarr"

        # Change ownership back to sonarr
        chown ${globals.sonarr.user}:${globals.sonarr.group} "$configFile"

        # Set username and password in database (using PBKDF2)
        dbFile="${stateDir}/sonarr.db"

        # Wait for database and Users table to be created (up to 30 seconds)
        for i in {1..30}; do
          if [ -f "$dbFile" ] && ${pkgs.sqlite}/bin/sqlite3 "$dbFile" "SELECT name FROM sqlite_master WHERE type='table' AND name='Users';" | grep -q Users; then
            break
          fi
          echo "Waiting for Sonarr to create Users table... ($i/30)"
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
        with open('${config.sops.secrets."sonarr/auth/password".path}', 'rb') as f:
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

        # Restart sonarr to pick up the new config
        systemctl restart sonarr.service
      '';
    };

    services.nginx.virtualHosts.localhost.locations."/sonarr" = {
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
}
