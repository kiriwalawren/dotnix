{
  flake.modules.nixos.homelab =
    {
      config,
      inputs,
      lib,
      ...
    }:
    let
      secretsDir = "/run/secrets-niks3";
      toGuestPath = p: "/run/host-secrets" + lib.removePrefix secretsDir p;
      hostSecret = name: toGuestPath config.sops.secrets.${name}.path;
      hostTemplate = name: toGuestPath config.sops.templates.${name}.path;

      niks3ListenAddress = "127.0.0.1:5751";
    in
    {
      imports = [ inputs.microvm.nixosModules.host ];

      sops.secrets."backblaze/kiriwalawrencache/key-id" = {
        path = "${secretsDir}/backblaze/key-id";
        mode = "0444";
      };
      sops.secrets."backblaze/kiriwalawrencache/application-key" = {
        path = "${secretsDir}/backblaze/application-key";
        mode = "0444";
      };
      sops.secrets."niks3/api-token" = {
        path = "${secretsDir}/niks3/api-token";
        mode = "0444";
      };
      sops.secrets."niks3/signing-key" = {
        path = "${secretsDir}/niks3/signing-key";
        mode = "0444";
      };

      sops.templates."headscale-auth-key-niks3" = {
        path = "${secretsDir}/headscale-auth-key";
        mode = "0444";
        content = config.sops.placeholder."headscale-auth-key";
      };

      sops.templates."cloudflare-ddns-niks3.env" = {
        group = "acme";
        mode = "0440";
        path = "${secretsDir}/cloudflare-ddns.env";
        inherit (config.sops.templates."cloudflare-ddns.env") content;
      };

      systemd.network = {
        enable = true;
        config.networkConfig = {
          ManageForeignRoutes = false;
          ManageForeignRoutingPolicyRules = false;
        };
        networks."10-microvm-niks3" = {
          matchConfig.Name = "vm-niks3";
          networkConfig = {
            Address = "10.20.0.1/24";
            ConfigureWithoutCarrier = true;
          };
        };
      };

      networking.firewall.extraForwardRules = ''
        iifname "vm-niks3" accept
        oifname "vm-niks3" ct state established,related accept
      '';

      networking.nftables = {
        enable = true;
        tables."microvm-niks3-nat" = {
          family = "inet";
          content = ''
            chain postrouting {
              type nat hook postrouting priority 100; policy accept;
              ip saddr 10.20.0.0/24 oifname != "vm-niks3" masquerade;
            }
          '';
        };
      };

      microvm.vms.niks3 = {
        restartIfChanged = true;
        config = {
          imports = [ inputs.niks3.nixosModules.default ];

          microvm = {
            hypervisor = "qemu";
            mem = 512;
            vcpu = 2;

            interfaces = [
              {
                type = "tap";
                id = "vm-niks3";
                mac = "02:00:00:00:00:02";
              }
            ];

            shares = [
              {
                tag = "ro-store";
                source = "/nix/store";
                mountPoint = "/nix/.ro-store";
                proto = "virtiofs";
              }
              {
                tag = "host-secrets";
                source = secretsDir;
                mountPoint = "/run/host-secrets";
                proto = "virtiofs";
              }
              {
                tag = "acme-state";
                source = "/var/lib/niks3-microvm/acme";
                mountPoint = "/var/lib/acme";
                proto = "virtiofs";
              }
            ];
          };

          networking = {
            hostName = "niks3";
            useDHCP = false;
            firewall.trustedInterfaces = [ "tailscale0" ];
          };

          systemd.network = {
            enable = true;
            networks."20-lan" = {
              matchConfig.Type = "ether";
              networkConfig = {
                Address = "10.20.0.2/24";
                Gateway = "10.20.0.1";
                DNS = "10.20.0.1";
              };
            };
          };

          services.niks3 = {
            enable = true;
            httpAddr = niks3ListenAddress;

            s3 = {
              endpoint = "s3.us-east-005.backblazeb2.com";
              bucket = "kiriwalawrencache";
              region = "us-east-005";
              useSSL = true;
              accessKeyFile = hostSecret "backblaze/kiriwalawrencache/key-id";
              secretKeyFile = hostSecret "backblaze/kiriwalawrencache/application-key";
            };

            apiTokenFile = hostSecret "niks3/api-token";
            signKeyFiles = [ (hostSecret "niks3/signing-key") ];

            cacheUrl = "https://cache.walawren.com";

            oidc.providers.github = {
              issuer = "https://token.actions.githubusercontent.com";
              audience = "https://niks3.walawren.com";
              boundClaims = {
                repository_owner = [ "kiriwalawren" ];
              };
            };
          };

          security.acme = {
            acceptTerms = true;
            defaults = {
              dnsProvider = "cloudflare";
              credentialsFile = hostTemplate "cloudflare-ddns-niks3.env";
              email = "kiri@walawren.com";
              dnsResolver = "10.20.0.1:53";
            };
            certs."walawren.com" = {
              domain = "*.walawren.com";
              group = "nginx";
              extraLegoFlags = [ "--dns.propagation-wait=60s" ];
            };
          };

          services.nginx = {
            enable = true;
            recommendedTlsSettings = true;
            recommendedOptimisation = true;
            recommendedGzipSettings = true;

            virtualHosts = {
              "_" = {
                default = true;
                extraConfig = ''
                  return 444;
                '';
              };

              "niks3.walawren.com" = {
                forceSSL = true;
                useACMEHost = "walawren.com";
                locations."/" = {
                  proxyPass = "http://${niks3ListenAddress}";
                  extraConfig = ''
                    proxy_connect_timeout 300s;
                    proxy_send_timeout 300s;
                    proxy_read_timeout 300s;
                  '';
                };
              };
            };
          };

          services.tailscale = {
            enable = true;
            authKeyFile = hostTemplate "headscale-auth-key-niks3";
            openFirewall = true;
            extraUpFlags = [
              "--login-server=https://headscale.walawren.com"
              "--advertise-tags=tag:niks3"
              "--accept-routes=false"
            ];
          };

          system.stateVersion = "25.11";
        };
      };
    };
}
