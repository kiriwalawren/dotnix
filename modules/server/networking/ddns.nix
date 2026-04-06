{ config, ... }:
let
  user = config.user.name;
in
{
  flake.modules.nixos.base =
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
          default = "";
          type = lib.types.str;
          description = "Domain to create a certificate for. If emtpy, a certificate will not be created.";
        };

        subdomains = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Subdomains to create A records for. If empty, server will not be publicly accessible.
          '';
        };
      };

      config = lib.mkIf (cfg.domain != "" || cfg.subdomains != [ ]) {
        # Explicitly create the cloudflare-ddns user/group so sops can set ownership
        # even when cloudflare-ddns service is not enabled (e.g. ACME-only, no subdomains).
        users.groups.${config.services.cloudflare-ddns.group} = { };
        users.users.${config.services.cloudflare-ddns.user} = {
          isSystemUser = true;
          group = config.services.cloudflare-ddns.group;
        };

        sops.secrets."cloudflare/api-token" = {
          owner = config.services.cloudflare-ddns.user or "root";
          group = "acme";
          mode = "0440";
        };
        sops.secrets."cloudflare/dns-api-token" = {
          owner = config.services.cloudflare-ddns.user or "root";
          group = "acme";
          mode = "0440";
        };
        sops.templates."cloudflare-ddns.env" = {
          owner = config.services.cloudflare-ddns.user or "root";
          group = "acme";
          mode = "0440";
          content = ''
            CLOUDFLARE_API_TOKEN=${config.sops.placeholder."cloudflare/api-token"}
            CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder."cloudflare/dns-api-token"}
            CF_API_TOKEN=${config.sops.placeholder."cloudflare/api-token"}
            CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare/dns-api-token"}
          '';
        };

        users.extraGroups.${config.services.cloudflare-ddns.group}.members = [ user ];

        services.cloudflare-ddns = lib.mkIf (cfg.subdomains != [ ]) {
          enable = true;

          domains = map (sd: "${sd}.${cfg.domain}") cfg.subdomains;
          credentialsFile = config.sops.templates."cloudflare-ddns.env".path;
        };

        security.acme = lib.mkIf (cfg.domain != "") {
          acceptTerms = true;
          defaults = {
            dnsProvider = "cloudflare";
            credentialsFile = config.sops.templates."cloudflare-ddns.env".path;
            email = "${config.networking.hostName}@${cfg.domain}";
            dnsResolver = "100.64.0.6:53";
          };
          certs.${cfg.domain} = {
            domain = "*.${cfg.domain}";
            group = "nginx";
            extraLegoFlags = [ "--dns.propagation-wait=60s" ];
          };
        };
      };
    };
}
