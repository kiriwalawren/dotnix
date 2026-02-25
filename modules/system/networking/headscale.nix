{
  flake.modules.nixos.headscale = {
    services.headscale = {
      enable = true;
      settings = {
        server_url = "https://headscale.walawren.com:443";
        dns = {
          base_domain = "tailnet.walawren.com";
          #   override_local_dns = true;
          #   # TODO: fill this with adguard instance tailscale ips (homelab and vps)
          #   nameservers.global = [ ];
        };
      };
    };

    services.nginx.virtualHosts."headscale.walawren.com" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true; # headscale needs this
        extraConfig = ''
          proxy_buffering off;
        '';
      };
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = "vps@walawren.com";
    };
  };
}
