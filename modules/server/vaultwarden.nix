{
  flake.modules.nixos.homelab =
    { config, ... }:
    let
      inherit (config.system) ddns;
      subdomain = "vault";
      domain = "${subdomain}.${ddns.domain}";
    in
    {
      sops.secrets."vaultwarden/admin-token" = { };

      sops.templates."vaultwarden.env" = {
        owner = config.users.users.vaultwarden.name;
        group = config.users.groups.vaultwarden.name;
        mode = "0440";
        content = ''
          ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/admin-token"}
        '';
      };

      services.vaultwarden = {
        inherit domain;
        enable = true;
        dbBackend = "postgresql";
        config = {
          SIGNUPS_ALLOWED = true;
          ENABLE_WEBSOCKET = true;
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = 8222;
        };
        environmentFile = config.sops.templates."vaultwarden.env".path;
        configurePostgres = true;
      };

      services.postgresql = {
        enable = true;
        ensureUsers = [
          {
            name = "vaultwarden";
            ensureDBOwnership = true;
          }
        ];
        ensureDatabases = [ "vaultwarden" ];
      };

      services.nginx = {
        virtualHosts.${domain} = {
          forceSSL = true;
          useACMEHost = ddns.domain;

          locations = {
            "/" = {
              proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
              recommendedProxySettings = true;
            };
            "= /notifications/anonymous-hub" = {
              proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
              proxyWebsockets = true;
            };
            "= /notifications/hub" = {
              proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
              proxyWebsockets = true;
            };
          };
        };
      };
    };
}
