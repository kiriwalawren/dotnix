{
  flake.modules.nixos.headscale = {
    services.headscale = {
      enable = true;
      settings = {
        server_url = "https://headscale.walawren.com:443";
        dns = {
          base_domain = "tailnet.walawren.com";
          # TODO: set to true after filling nameservers.global
          override_local_dns = false;
          # # TODO: fill this with adguard instance tailscale ips (homelab and vps)
          # nameservers.global = [ ];
        };
      };
    };

    services.nginx.virtualHosts."headscale.walawren.com" = {
      useACMEHost = "walawren.com";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true; # headscale needs this
        extraConfig = ''
          proxy_buffering off;
        '';
      };
    };
  };

  flake.modules.nixos.ddns = {
    services.nginx.virtualHosts."headscale.walawren.com".useACMEHost = "walawren.com";
  };
}
