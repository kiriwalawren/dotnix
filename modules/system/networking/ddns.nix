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
        sops.secrets.cloudflare-api-token = {
          owner = config.services.cloudflare-ddns.user;
          inherit (config.services.cloudflare-ddns) group;
          mode = "0440";
        };

        users.extraGroups.${config.services.cloudflare-ddns.group}.members = [ user ];

        services.cloudflare-ddns = {
          enable = true;

          domains = map (sd: "${sd}.${cfg.domain}") cfg.subdomains;
          credentialsFile = config.sops.secrets.cloudflare-api-token.path;
        };

        security.acme = {
          acceptTerms = true;
          defaults = {
            dnsProvider = "cloudflare";
            credentialsFile = config.sops.secrets.cloudflare-api-token.path;
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
