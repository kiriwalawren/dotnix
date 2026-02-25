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
      sops.secrets."headplane/headscale-api-key" = {
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
            port = 4040;
            cookie_secret_path = config.sops.secrets."headplane/cookie-secret".path;
            cookie_secure = true;
          };

          headscale = {
            config_path = config.services.headscale.configFile;
            url = "https://headscale.${config.system.ddns.domain}";
          };

          integration.agent = {
            enabled = true;
            pre_authkey_path = config.sops.secrets."headplane/headscale-pre-authkey".path;
          };

          oidc = {
            inherit (config.system.auth) issuer;
            client_id = config.system.auth.headscaleClientId;
            client_secret_path = config.sops.secrets."pocket-id/headscale-client-secret".path;
            redirect_uri = "https://headplane.${config.system.ddns.domain}/admin/oidc/callback";
            headscale_api_key_path = config.sops.secrets."headplane/headscale-api-key".path;
          };
        };
      };

      services.nginx.virtualHosts."headplane.${config.system.ddns.domain}" = {
        useACMEHost = config.system.ddns.domain;
        forceSSL = true;
        locations."/" = {
          proxyPass = with config.services.headplane.settings.server; "http://${host}:${toString port}";
          recommendedProxySettings = true;
        };
      };
    };
}
