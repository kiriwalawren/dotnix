{
  flake.modules.nixos.adguardhome =
    { config, lib, ... }:
    let
      cfg = config.server.adguardhome;

      webUIPort = 3000;
    in
    {
      options.server.adguardhome = {
        serverIP = lib.mkOption {
          type = lib.types.str;
          default = null;
          description = "IP Address of the server that is running AdGuard Home.";
        };

        subdomain = lib.mkOption {
          type = lib.types.str;
          default = "dns";
          example = "dns2";
          description = "Subomain for accessing this adguard instance on `system.ddns.domain`";
        };
      };

      config = {
        # Allow pre-binding
        boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = 1;

        networking.nameservers = [ "127.0.0.1" ];
        services.resolved.settings.Resolve.Domains = [ "~." ];

        # I have to override the user so that I can configure
        # Mullvan VPN Bypass
        users.users.adguardhome = {
          isSystemUser = true;
          uid = 300;
          group = "adguardhome";
        };
        users.groups.adguardhome = { };

        systemd.tmpfiles.rules = [
          "Z /var/lib/AdGuardHome 0750 adguardhome adguardhome -"
        ];

        systemd.services.adguardhome = {
          serviceConfig = {
            DynamicUser = lib.mkForce false;
            User = "adguardhome";
            Group = "adguardhome";
          };
        };

        networking.nftables.tables."mullvad-adguard" =
          let
            adguardUid = toString config.users.users.adguardhome.uid;
          in
          {
            family = "inet";
            content = ''
              chain outgoing {
                type route hook output priority -100; policy accept;
                meta skuid ${adguardUid} ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
              }
            '';
          };

        services.adguardhome = {
          enable = true;
          mutableSettings = false;
          settings = {
            http = {
              address = "127.0.0.1:${builtins.toString webUIPort}";
            };
            users = [
              {
                name = "admin";
                password = "$2a$10$pWr1lPpR/D6P2uIy37eyEuLw8vKA04nivUo8im.SxIPVtvJC40Rlu";
              }
            ];
            dns = {
              bind_hosts = [
                "127.0.0.1"
                cfg.serverIP
              ];
              port = 53;
              bootstrap_dns = [
                "9.9.9.10"
                "149.112.112.10"
                "2620:fe::10"
                "2620:fe::fe:10"
              ];
              upstream_dns = [
                "https://unfiltered.adguard-dns.com/dns-query"
                "https://cloudflare-dns.com/dns-query"
              ];
            };
            filters =
              map
                (url: {
                  enabled = true;
                  inherit url;
                })
                [
                  "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt" # AdGuard DNS filter
                  "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt" # AdWay Default Blocklist
                  "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt" # The Big List of Hacked Malware Web Sites
                  "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt" # malicious url blocklist
                  "https://adguardteam.github.io/HostlistsRegistry/assets/filter_33.txt" # Steven Black's hosts file
                  "https://adguardteam.github.io/HostlistsRegistry/assets/filter_18.txt" # Filter Phishing domains
                  "https://adguardteam.github.io/HostlistsRegistry/assets/filter_12.txt" # Anti-mailware list
                  "https://adguardteam.github.io/HostlistsRegistry/assets/filter_30.txt" # Filter Phishing domains based on PhishTank and OpenPhish lists"
                  "https://adguardteam.github.io/HostlistsRegistry/assets/filter_57.txt" # Block dating sites
                  "https://adguardteam.github.io/HostlistsRegistry/assets/filter_47.txt" # Block gambling sites
                  "https://big.oisd.nl"
                ];
          };
        };

        services.nginx.virtualHosts."${cfg.subdomain}.${config.system.ddns.domain}" = {
          forceSSL = true;
          useACMEHost = config.system.ddns.domain;

          locations."/" = {
            proxyPass = "http://127.0.0.1:${builtins.toString webUIPort}";
            recommendedProxySettings = true;
            extraConfig = ''
              proxy_redirect off;
            '';
          };
        };
      };
    };
}
