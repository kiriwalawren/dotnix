{
  flake.modules.nixos.headscale =
    { config, ... }:
    {
      system.ddns.subdomains = [ "headscale" ];

      sops.secrets."pocket-id/headscale-client-secret" = {
        owner = "headscale";
        group = "headscale";
      };

      services.headscale = {
        enable = true;
        settings = {
          log.level = "debug";
          server_url = "https://headscale.${config.system.ddns.domain}:443";
          metrics_listen_addr = "127.0.0.1:9090";
          dns = {
            base_domain = "walawren.hs.net";
            # TODO: set to true after filling nameservers.global
            override_local_dns = false;
            # # TODO: fill this with adguard instance tailscale ips (homelab and vps)
            # nameservers.global = [ ];
          };
          oidc = {
            issuer = config.system.auth.issuer;
            client_id = "62a2d93a-4442-4e94-8d4d-2de1c61ade61";
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
          proxyPass = "http://127.0.0.1:8080";
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
