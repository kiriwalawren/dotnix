{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.server.adguardhome;
in
{
  options.server.adguardhome = {
    enable = mkEnableOption "AdGuard Home";
    serverIP = mkOption {
      type = types.str;
      default = "100.99.237.58";
      description = "IP Address of the server that is running AdGuard Home";
    };
  };

  config = mkIf cfg.enable {
    users.users.adguardhome = {
      isSystemUser = true;
      uid = 300;
      group = "adguardhome";
    };
    users.groups.adguardhome = { };

    systemd.tmpfiles.rules = [
      "Z /var/lib/AdGuardHome 0750 adguardhome adguardhome -"
    ];
    systemd.services.adguardhome.serviceConfig = {
      DynamicUser = mkForce false;
      User = "adguardhome";
      Group = "adguardhome";
    };

    services.adguardhome = {
      enable = true;
      mutableSettings = false;
      settings = {
        users = [
          {
            name = "admin";
            password = "$2a$10$pWr1lPpR/D6P2uIy37eyEuLw8vKA04nivUo8im.SxIPVtvJC40Rlu";
          }
        ];
        dns = {
          bind_hosts = [ cfg.serverIP ];
          port = 53;
          bootstrap_dns = [
            "9.9.9.10"
            "149.112.112.10"
            "2620:fe::10"
            "2620:fe::fe:10"
          ];
          upstream_dns = [
            # AdGuard DNS (primary ad-blocking DNS)
            "94.140.14.14"
            "94.140.15.15"
            # Control D Ads & Trackers (backup ad-blocking DNS)
            "76.76.2.2"
            "76.76.10.2"
            # # Quad9 (fallback with malware blocking)
            # "9.9.9.9"
            # "149.112.112.112"
          ];
        };
        filtering = {
          rewrites = [
            {
              enabled = true;
              domain = "*.homelab";
              answer = cfg.serverIP;
            }
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
  };
}
