{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  inherit (config) server;
  inherit (server) globals;
  cfg = config.server.radarr;
  port = 7878;
  stateDir = "${server.stateDir}/radarr";
  mediaDir = "${server.mediaDir}/movies";
  arrCommon = import ./arr-common.nix {inherit lib pkgs;};
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

    config = mkOption {
      type = arrCommon.arrConfigModule;
      default = {};
      description = ''
        Radarr configuration options that will be set via the API.
      '';
    };
  };

  config = mkIf (server.enable && cfg.enable) {
    # Set default values for radarr-specific settings
    server.radarr.config = mkMerge [
      {
        port = mkDefault port;
        branch = mkDefault "master";
        instanceName = mkDefault "Radarr";
        urlBase = mkDefault "/radarr";
        rootFolders = mkDefault [mediaDir];
        apiKeySecret = mkDefault config.sops.secrets."radarr/api_key".path;
        usernameSecret = mkDefault config.sops.secrets."radarr/auth/username".path;
        passwordSecret = mkDefault config.sops.secrets."radarr/auth/password".path;
      }
      cfg.config
    ];

    # Register directories to be created
    server.dirRegistrations = [
      {
        inherit (globals.radarr) group;
        dir = stateDir;
        owner = globals.radarr.user;
      }
      {
        inherit (globals.radarr) group;
        dir = mediaDir;
        owner = globals.libraryOwner.user;
      }
    ];

    sops.secrets = {
      "radarr/api_key" = {
        inherit (globals.radarr) group;
        owner = globals.radarr.user;
        mode = "0440";
      };
      "radarr/api_key_env" = {
        inherit (globals.radarr) group;
        owner = globals.radarr.user;
        mode = "0440";
      };
      "radarr/auth/username" = {
        inherit (globals.radarr) group;
        owner = globals.radarr.user;
        mode = "0440";
      };
      "radarr/auth/password" = {
        inherit (globals.radarr) group;
        owner = globals.radarr.user;
        mode = "0440";
      };
    };

    users = {
      groups.${globals.radarr.group}.gid = globals.gids.${globals.radarr.group};
      users.${globals.radarr.user} = {
        inherit (globals.radarr) group;
        isSystemUser = true;
        uid = globals.uids.${globals.radarr.user};
      };
    };

    services.radarr = {
      inherit (cfg) enable;
      inherit (globals.radarr) user group;
      settings.server.port = port;
      dataDir = stateDir;
      environmentFiles = [config.sops.secrets."radarr/api_key_env".path];
    };

    # Ensure radarr starts after directories are created and VPN is up (if enabled)
    systemd.services.radarr = {
      after = ["server-setup-dirs.service"] ++ (optional config.system.vpn.enable "mullvad-config.service");
      requires = ["server-setup-dirs.service"];
      wants = optional config.system.vpn.enable "mullvad-config.service";
    };

    # Configure Radarr via API
    systemd.services.radarr-config = arrCommon.mkArrConfigService "radarr" config.server.radarr.config;

    services.nginx.virtualHosts.localhost.locations."/radarr" = {
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
