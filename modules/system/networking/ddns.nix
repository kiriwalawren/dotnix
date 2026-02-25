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
      options.system.ddns = with lib.types; {
        domains = lib.mkOption {
          default = [ ];
          type = listOf str;
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
          inherit (cfg) domains;

          enable = true;
          credentialsFile = config.sops.secrets.cloudflare-api-token.path;
        };

        security.acme = {
          acceptTerms = true;
          defaults = {
            dnsProvider = "cloudflare";
            credentialsFile = config.sops.secrets.cloudflare-api-token.path;
            email = "vps@walawren.com";
          };
          certs."walawren.com" = {
            domain = "*.walawren.com";
            group = "nginx";
          };
        };
      };
    };
}
