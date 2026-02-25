{
  flake.modules.nixos.auth =
    { config, lib, ... }:
    let
      domain = "auth.${config.system.ddns.domain}";
    in
    {
      options.system.auth = {
        issuer = lib.mkOption {
          type = lib.types.str;
          default = "https://${domain}";
          readOnly = true;
        };
      };

      config = {
        system.ddns.subdomains = [ "auth" ];

        sops.secrets."pocket-id/encryption-key" = {
          owner = "pocket-id";
          group = "pocket-id";
        };

        services.pocket-id = {
          enable = true;
          credentials = {
            ENCRYPTION_KEY = config.sops.secrets."pocket-id/encryption-key".path;
          };
          settings = {
            APP_URL = config.system.auth.issuer;
            TRUST_PROXY = true;
            PORT = 1411;
          };
        };

        services.nginx.virtualHosts.${domain} = {
          useACMEHost = config.system.ddns.domain;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:1411";
            proxyWebsockets = true;
          };
        };
      };
    };
}
