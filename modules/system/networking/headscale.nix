{
  flake.modules.nixos.headscale =
    { config, ... }:
    {
      system.ddns.subdomains = [ "headscale" ];

      # sops.secrets.headscale-oidc-client-secret = {
      #   owner = "headscale";
      #   group = "headscale";
      # };

      services.headscale = {
        enable = true;
        settings = {
          server_url = "https://headscale.${config.system.ddns.domain}:443";
          metrics_listen_addr = "127.0.0.1:9090";
          dns = {
            base_domain = "walawren.hs.net";
            # TODO: set to true after filling nameservers.global
            override_local_dns = false;
            # # TODO: fill this with adguard instance tailscale ips (homelab and vps)
            # nameservers.global = [ ];
          };
          # oidc = {
          #   issuer = config.system.auth.issuer;
          #   client_id = "headscale";
          #   client_secret_path = config.sops.secrets.headscale-oidc-client-secret.path;
          #   scope = [
          #     "openid"
          #     "profile"
          #     "email"
          #   ];
          # };
        };
      };

      services.nginx.virtualHosts."headscale.${config.system.ddns.domain}" = {
        useACMEHost = config.system.ddns.domain;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_buffering off;
          '';
        };
      };
    };
}
