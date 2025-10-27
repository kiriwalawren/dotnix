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
    # Set default values for sonarr-specific settings
    server.sonarr.config = mkMerge [
      {
        port = mkDefault port;
        branch = mkDefault "main";
        instanceName = mkDefault "Sonarr";
        urlBase = mkDefault "/sonarr";
        rootFolders = mkDefault [tvDir animeDir];
        apiKeySecret = mkDefault config.sops.secrets."sonarr/api_key".path;
        usernameSecret = mkDefault config.sops.secrets."sonarr/auth/username".path;
        passwordSecret = mkDefault config.sops.secrets."sonarr/auth/password".path;
      }
      cfg.config
    ];

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
      "sonarr/api_key_env" = {
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
      environmentFiles = [config.sops.secrets."sonarr/api_key_env".path];
    };

    # Ensure sonarr starts after directories are created and VPN is up (if enabled)
    systemd.services.sonarr = {
      after = ["server-setup-dirs.service"] ++ (optional config.system.vpn.enable "mullvad-config.service");
      requires = ["server-setup-dirs.service"];
      wants = optional config.system.vpn.enable "mullvad-config.service";
    };

    # Configure Sonarr via API
    systemd.services.sonarr-config = arrCommon.mkArrConfigService "sonarr" config.server.sonarr.config;

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
