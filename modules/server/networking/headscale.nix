{
  lib,
  inputs,
  ...
}:
{
  nixpkgs.overlays = [ inputs.headplane.overlays.default ];

  flake.modules.nixos.base =
    { config, ... }:
    {
      options.tailscale.ips = {
        homelab = lib.mkOption {
          type = lib.types.str;
          default = "100.64.0.6";
          description = "IP Address of homelab.";
          readOnly = true;
        };

        vps = lib.mkOption {
          type = lib.types.str;
          default = "100.64.0.4";
          description = "IP Address of vps.";
          readOnly = true;
        };
      };

      config.services.headscale.settings.dns.base_domain = "hs.${config.system.ddns.domain}";
    };

  flake.modules.nixos.vps =
    { config, ... }:
    {
      imports = [ inputs.headplane.nixosModules.headplane ];

      sops.secrets."headplane/cookie-secret" = {
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

      systemd.services.headscale = {
        after = [ "pocket-id.service" ];
        requires = [ "pocket-id.service" ];
      };

      system.backup.paths = [ "/var/lib/headscale/" ];

      services.headscale = {
        enable = true;
        address = "127.0.0.1";
        port = 9090;
        settings = {
          # log.level = "debug";
          server_url = "https://headscale.${config.system.ddns.domain}";

          policy = {
            mode = "file";
            path = builtins.toFile "acl-policy.json" (
              builtins.toJSON {
                tagOwners = {
                  "tag:nixflix" = [ "kiriwalawren@" ];
                  "tag:dns" = [ "kiriwalawren@" ];
                  "tag:ci" = [ "kiriwalawren@" ];
                  "tab:niks3" = [ "kiriwalawren@" ];
                };

                acls = [
                  # kiri can SSH into her tagged machines, or use HTTP(S)
                  {
                    action = "accept";
                    src = [ "kiriwalawren@" ];
                    dst = [
                      "tag:nixflix:22,80,443"
                      "tag:dns:22,80,443"
                    ];
                  }

                  # all users can reach http(s) on 80 and 443
                  {
                    action = "accept";
                    src = [ "autogroup:member" ];
                    dst = [ "tag:nixflix:80,443" ];
                  }

                  # ci can reach niks3 https(s) on 80 and 443
                  {
                    action = "accept";
                    src = [ "tag:ci" ];
                    dst = [ "tag:niks3:80,443" ];
                  }

                  # all users and devices can reach DNS on dns-tagged machines
                  {
                    action = "accept";
                    src = [
                      "autogroup:member"
                      "autogroup:tagged"
                    ];
                    dst = [ "tag:dns:53" ];
                  }

                  # all users can route through exit nodes
                  {
                    action = "accept";
                    src = [ "autogroup:member" ];
                    dst = [ "autogroup:internet:*" ];
                  }
                ];
              }
            );
          };

          dns = {
            override_local_dns = true;
            magic_dns = true;
            nameservers.global = [
              "100.64.0.6"
              "100.64.0.4"
            ];
            extra_records = [
              {
                name = "nzb.${config.system.ddns.domain}";
                type = "A";
                value = config.tailscale.ips.homelab;
              }
              {
                name = "torrent.${config.system.ddns.domain}";
                type = "A";
                value = config.tailscale.ips.homelab;
              }
              {
                name = "tv.${config.system.ddns.domain}";
                type = "A";
                value = config.tailscale.ips.homelab;
              }
              {
                name = "anime.${config.system.ddns.domain}";
                type = "A";
                value = config.tailscale.ips.homelab;
              }
              {
                name = "movies.${config.system.ddns.domain}";
                type = "A";
                value = config.tailscale.ips.homelab;
              }
              {
                name = "music.${config.system.ddns.domain}";
                type = "A";
                value = config.tailscale.ips.homelab;
              }
              {
                name = "indexers.${config.system.ddns.domain}";
                type = "A";
                value = config.tailscale.ips.homelab;
              }
              {
                name = "watch.${config.system.ddns.domain}";
                type = "A";
                value = config.tailscale.ips.homelab;
              }
              {
                name = "request.${config.system.ddns.domain}";
                type = "A";
                value = config.tailscale.ips.homelab;
              }
              {
                name = "photos.${config.system.ddns.domain}";
                type = "A";
                value = config.tailscale.ips.homelab;
              }
              {
                name = "vault.${config.system.ddns.domain}";
                type = "A";
                value = config.tailscale.ips.homelab;
              }
              {
                name = "dns.${config.system.ddns.domain}";
                type = "A";
                value = config.tailscale.ips.vps;
              }
              {
                name = "dns2.${config.system.ddns.domain}";
                type = "A";
                value = config.tailscale.ips.homelab;
              }
              {
                name = "niks3.${config.system.ddns.domain}";
                type = "A";
                value = config.tailscale.ips.homelab;
              }
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
            api_key_path = config.sops.secrets."headplane/headscale-api-key".path;
          };

          integration.agent = {
            enabled = true;
          };

          oidc = {
            inherit (config.system.auth) issuer;
            client_id = config.system.auth.headscaleClientId;
            client_secret_path = config.sops.secrets."pocket-id/headscale-client-secret".path;
            use_pkce = true;
          };
        };
      };

      services.nginx.virtualHosts."headscale.${config.system.ddns.domain}" = {
        useACMEHost = config.system.ddns.domain;
        forceSSL = true;

        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:${toString config.services.headscale.port}";
            recommendedProxySettings = true;
            proxyWebsockets = true;
            extraConfig = ''
              proxy_buffering off;
              add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;
            '';
          };

          "/admin" = {
            proxyPass = "http://127.0.0.1:${toString config.services.headplane.settings.server.port}";
            recommendedProxySettings = true;
            extraConfig = ''
              proxy_buffering off;
            '';
          };
        };
      };
    };
}
