{ inputs, ... }:
{
  nixpkgs.overlays = [ inputs.headplane.overlays.default ];

  flake.modules.nixos.headscale =
    { config, ... }:
    {
      imports = [ inputs.headplane.nixosModules.headplane ];

      sops.secrets."headplane/cookie-secret" = {
        owner = "headscale";
        group = "headscale";
      };
      sops.secrets."headplane/headscale-pre-authkey" = {
        owner = "headscale";
        group = "headscale";
      };

      system.ddns.subdomains = [ "headplane" ];

      services.headplane = {
        enable = true;
        debug = true;
        settings = {
          server = {
            host = "127.0.0.1";
            port = 3000;
            cookie_secret_path = config.sops.secrets."headplane/cookie-secret".path;
            cookie_secure = true;
          };

          headscale = {
            config_file = config.services.headscale.config_file;
            url = "${
              if config.services.headscale.settings.tls_key_path == null then "http" else "https"
            }://${config.services.headscale.settings.listen_addr}";
            public_url = "https://headscale.${config.dns.domain}";
          };

          integration.agent = {
            enabled = true;
            pre_authkey_path = config.sops.secrets."headplane/headscale-pre-authkey".path;
          };

          oidc = {
            issuer = config.system.auth.issuer;
            client_id = "62a2d93a-4442-4e94-8d4d-2de1c61ade61";
            client_secret_path = config.sops.secrets."pocket-id/headscale-client-secret".path;
            redirect_uri = "https://headplane.${config.dns.domain}/admin/oidc/callback";
          };
        };
      };

      services.nginx.virtualHosts."headplane.${config.system.ddns.domain}" = {
        useACMEHost = config.system.ddns.domain;
        forceSSL = true;
        locations."/" = {
          proxyPass = with config.services.headplane.settings.server; "http://${host}:${port}";
          recommendedProxySettings = true;
        };
      };
    };
}
