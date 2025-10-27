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
  };

  config = mkIf (server.enable && cfg.enable) {
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
    };

    # Ensure radarr starts after directories are created and VPN is up (if enabled)
    systemd.services.radarr = {
      after = ["server-setup-dirs.service"] ++ (optional config.system.vpn.enable "mullvad-config.service");
      requires = ["server-setup-dirs.service"];
      wants = optional config.system.vpn.enable "mullvad-config.service";
    };

    # Configure Radarr
    systemd.services.radarr-config = arrCommon.mkArrConfigService {
      serviceName = "radarr";
      inherit port stateDir;
      inherit (globals.radarr) user group;
      apiKeySecret = config.sops.secrets."radarr/api_key".path;
      usernameSecret = config.sops.secrets."radarr/auth/username".path;
      passwordSecret = config.sops.secrets."radarr/auth/password".path;
      urlBase = "/radarr";
      rootFolders = [mediaDir];
    };

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
