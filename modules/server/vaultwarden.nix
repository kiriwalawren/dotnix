{
  flake.modules.nixos.homelab =
    { config, ... }:
    let
      ddns = config.system.ddns;
      subdomain = "vault";
      domain = "${subdomain}.${ddns.domain}";
    in
    {
      services.vaultwarden = {
        enable = true;
        domain = "https://${domain}";
        dbBackend = "postgresql";
        config = {
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = 8200;
        };
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
