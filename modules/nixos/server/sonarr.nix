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
  arrCommon = import ./arr-common.nix {inherit lib pkgs;};
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

    config = mkOption {
      type = arrCommon.arrConfigModule;
      default = {};
      description = ''
        Sonarr configuration options that will be set via the API.
      '';
    };
  };

  config = mkIf (server.enable && cfg.enable) {
    # Set defaults for sonarr-specific settings
    server.sonarr.config = {
      port = mkDefault port;
      branch = mkDefault "main";
      instanceName = mkDefault "Sonarr";
      urlBase = mkDefault "/sonarr";
      rootFolders = mkDefault [tvDir animeDir];
      apiKeySecret = mkDefault config.sops.secrets."sonarr/api_key".path;
      usernameSecret = mkDefault config.sops.secrets."sonarr/auth/username".path;
      passwordSecret = mkDefault config.sops.secrets."sonarr/auth/password".path;
    };

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
      settings = {
        auth = {
          required = "Enabled";
          method = "Forms";
        };
        server = {
          inherit port;
          inherit (cfg.config) urlBase;
        };
      };
    };

    systemd.services = {
      # Create environment file setup service
      sonarr-env = {
        description = "Setup Sonarr environment file";
        wantedBy = ["sonarr.service"];
        before = ["sonarr.service"];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script = ''
          mkdir -p /run/sonarr
          echo "SONARR__AUTH__APIKEY=$(cat ${config.sops.secrets."sonarr/api_key".path})" > /run/sonarr/env
          chown ${globals.sonarr.user}:${globals.sonarr.group} /run/sonarr/env
          chmod 0400 /run/sonarr/env
        '';
      };

      # Ensure sonarr starts after directories are created and VPN is up (if enabled)
      sonarr = {
        after = ["server-setup-dirs.service" "sonarr-env.service"] ++ (optional config.system.vpn.enable "mullvad-config.service");
        requires = ["server-setup-dirs.service" "sonarr-env.service"];
        wants = optional config.system.vpn.enable "mullvad-config.service";
        serviceConfig.EnvironmentFile = "/run/sonarr/env";
      };

      # Configure Sonarr via API
      sonarr-config = arrCommon.mkArrConfigService "sonarr" cfg.config;
    };

    services.nginx.virtualHosts.localhost.locations."${cfg.config.urlBase}" = {
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
