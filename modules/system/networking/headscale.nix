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
      sops.secrets."pocket-id/headscale-client-secret" = {
        owner = "headscale";
        group = "headscale";
      };

      system.ddns.subdomains = [ "headscale" ];

      services.headscale = {
        enable = true;
        address = "127.0.0.1";
        port = 9090;
        settings = {
          # log.level = "debug";
          server_url = "https://headscale.${config.system.ddns.domain}";
          policy.mode = "database";

          dns = {
            base_domain = "walawren.hs.net";
            override_local_dns = true;
            nameservers.global = [
              "100.64.0.6"
              "100.64.0.4"
            ];
          };

          oidc = {
            inherit (config.system.auth) issuer;
            client_id = config.system.auth.headscaleClientId;
            client_secret_path = config.sops.secrets."pocket-id/headscale-client-secret".path;
            scope = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
            pkce = {
              enabled = true;
              method = "S256";
            };
          };
        };
      };

      services.headplane = {
        enable = true;
        # debug = true;
        settings = {
          server = {
            host = "127.0.0.1";
            port = 4040;
            base_url = "https://headscale.${config.system.ddns.domain}/admin";
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
            headscale_api_key_path = config.sops.secrets."headplane/headscale-api-key".path;
            use_pkce = true;
          };
        };
      };

      services.nginx.virtualHosts."headscale.${config.system.ddns.domain}" = {
        useACMEHost = config.system.ddns.domain;
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.headscale.port}";
          recommendedProxySettings = true;
          proxyWebsockets = true;
          extraConfig = ''
            proxy_buffering off;
            add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;
          '';
        };

        locations."/admin" = {
          proxyPass = "http://127.0.0.1:${toString config.services.headplane.settings.server.port}";
          recommendedProxySettings = true;
          extraConfig = ''
            proxy_buffering off;
          '';
        };
      };
    };
}
