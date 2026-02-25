{
  flake.modules.nixos.headscale =
    { config, ... }:
    {
      sops.secrets."pocket-id/headscale-client-secret" = {
        owner = "headscale";
        group = "headscale";
      };

      system.ddns.subdomains = [ "headscale" ];

      services.headscale = {
        enable = true;
        address = "127.0.0.1";
        port = 9090;
        settings = {
          # log.level = "debug";
          server_url = "https://headscale.${config.system.ddns.domain}";
          dns = {
            base_domain = "walawren.hs.net";
            # TODO: set to true after filling nameservers.global
            override_local_dns = false;
            # # TODO: fill this with adguard instance tailscale ips (homelab and vps)
            # nameservers.global = [ ];
          };
          oidc = {
            inherit (config.system.auth) issuer;
            client_id = config.system.auth.headscaleClientId;
            client_secret_path = config.sops.secrets."pocket-id/headscale-client-secret".path;
            scope = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
            pkce = {
              enabled = true;
              method = "S256";
            };
          };
        };
      };

      services.nginx.virtualHosts."headscale.${config.system.ddns.domain}" = {
        useACMEHost = config.system.ddns.domain;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.headscale.port}";
          recommendedProxySettings = true;
          proxyWebsockets = true;
          extraConfig = ''
            proxy_buffering off;
            add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;
          '';
        };
      };
    };
}
