{ config, ... }:
let
  nixosModules = config.flake.modules.nixos;
in
{
  flake.modules.nixos.headscale =
    { config, ... }:
    {
      imports = [ nixosModules.ddns ];

      system.ddns.subdomains = [ "headscale" ];

      services.headscale = {
        enable = true;
        settings = {
          server_url = "https://headscale.${config.system.ddns.domain}:443";
          dns = {
            base_domain = "walawren.hs.net";
            # TODO: set to true after filling nameservers.global
            override_local_dns = false;
            # # TODO: fill this with adguard instance tailscale ips (homelab and vps)
            # nameservers.global = [ ];
          };
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
