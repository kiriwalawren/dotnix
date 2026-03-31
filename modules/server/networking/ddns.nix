{ config, ... }:
let
  user = config.user.name;
in
{
  flake.modules.nixos.ddns =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.system.ddns;
    in
    {
      options.system.ddns = {
        domain = lib.mkOption {
          default = null;
          type = lib.types.str;
        };

        subdomains = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      };

      config = {
        sops.secrets."cloudflare/api-token" = {
          owner = config.services.cloudflare-ddns.user;
          inherit (config.services.cloudflare-ddns) group;
          mode = "0440";
        };
        sops.secrets."cloudflare/dns-api-token" = {
          owner = config.services.cloudflare-ddns.user;
          inherit (config.services.cloudflare-ddns) group;
          mode = "0440";
        };
        sops.templates."cloudflare-ddns.env" = {
          owner = config.services.cloudflare-ddns.user;
          inherit (config.services.cloudflare-ddns) group;
          mode = "0440";
          content = ''
            CLOUDFLARE_API_TOKEN=${config.sops.placeholder."cloudflare/api-token"}
            CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder."cloudflare/dns-api-token"}
          '';
        };

        users.extraGroups.${config.services.cloudflare-ddns.group}.members = [ user ];

        services.cloudflare-ddns = {
          enable = true;

          domains = map (sd: "${sd}.${cfg.domain}") cfg.subdomains;
          credentialsFile = config.sops.templates."cloudflare-ddns.env".path;
        };

        security.acme = {
          acceptTerms = true;
          defaults = {
            dnsProvider = "cloudflare";
            credentialsFile = config.sops.templates."cloudflare-ddns.env".path;
            email = "${config.networking.hostName}@${cfg.domain}";
          };
          certs.${cfg.domain} = {
            domain = "*.${cfg.domain}";
            group = "nginx";
          };
        };
      };
    };
}
