{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.server.radarr;
  globals = config.server.globals;
  server = config.server;
  port = 7878;
  stateDir = "${server.stateDir}/radarr";
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
  };

  config = mkIf (server.enable && cfg.enable) {
    sops.secrets."radarr/api_key" = {
      owner = globals.radarr.user;
      group = globals.radarr.group;
      mode = "0440";
    };
    sops.secrets."radarr/auth/username" = {
      owner = globals.radarr.user;
      group = globals.radarr.group;
      mode = "0440";
    };
    sops.secrets."radarr/auth/password" = {
      owner = globals.radarr.user;
      group = globals.radarr.group;
      mode = "0440";
    };

    systemd.tmpfiles.rules = [
      "d '${server.stateDir}'                0755 root root - -"
      "d '${stateDir}'                       0755 ${globals.radarr.user} ${globals.radarr.group} - -"
      "d '${server.mediaDir}/library'        0775 ${globals.libraryOwner.user} ${globals.libraryOwner.group} - -"
      "d '${server.mediaDir}/library/movies' 0775 ${globals.libraryOwner.user} ${globals.libraryOwner.group} - -"
    ];

    users = {
      groups.${globals.radarr.group}.gid = globals.gids.${globals.radarr.group};
      users.${globals.radarr.user} = {
        isSystemUser = true;
        group = globals.radarr.group;
        uid = globals.uids.${globals.radarr.user};
      };
    };

    services.radarr = {
      enable = cfg.enable;
      user = globals.radarr.user;
      group = globals.radarr.group;
      settings.server.port = port;
      dataDir = stateDir;
    };

    # Inject secrets into Radarr config
    systemd.services.radarr-secrets = {
      description = "Inject secrets into Radarr configuration";
      after = ["radarr.service"];
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
          echo "Waiting for Radarr to create config file... ($i/30)"
          sleep 1
        done

        if [ ! -f "$configFile" ]; then
          echo "Config file was not created, exiting"
          exit 1
        fi

        # Read secrets
        API_KEY=$(cat ${config.sops.secrets."radarr/api_key".path})
        AUTH_USER=$(cat ${config.sops.secrets."radarr/auth/username".path})
        AUTH_PASS=$(cat ${config.sops.secrets."radarr/auth/password".path})

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
        set_element "UrlBase" "/radarr"

        # Change ownership back to radarr
        chown ${globals.radarr.user}:${globals.radarr.group} "$configFile"

        # Set username and password in database (using PBKDF2)
        dbFile="${stateDir}/radarr.db"

        # Generate PBKDF2 hash using Python
        read SALT HASHED_PASSWORD <<< $(echo -n "$AUTH_PASS" | ${pkgs.python3}/bin/python3 -c "
import base64
import hashlib
import secrets
import sys

password = sys.stdin.read()
salt = secrets.token_bytes(16)
iterations = 10000

# PBKDF2-HMAC-SHA256
hashed = hashlib.pbkdf2_hmac('sha256', password.encode(), salt, iterations)

print(base64.b64encode(salt).decode(), base64.b64encode(hashed).decode())
")

        # Insert or replace user in database
        ${pkgs.sqlite}/bin/sqlite3 "$dbFile" "
          DELETE FROM Users;
          INSERT INTO Users (Id, Identifier, Username, Password, Salt, Iterations)
          VALUES (1, lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || substr(hex(randomblob(2)),2) || '-' || substr('89ab',abs(random()) % 4 + 1, 1) || substr(hex(randomblob(2)),2) || '-' || hex(randomblob(6))), '$AUTH_USER', '$HASHED_PASSWORD', '$SALT', 10000);
        "

        # Restart radarr to pick up the new config
        systemctl restart radarr.service
      '';
    };

    services.nginx = {
      enable = true;

      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      virtualHosts."localhost" = {
        listen = [
          {
            addr = "0.0.0.0";
            port = 80;
          }
        ];

        serverName = "localhost";
        default = true;

        locations."/radarr" = {
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
    };
  };
}
