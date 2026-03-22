{ config, ... }:
let
  tailscaleIps = config.tailscale.ips;
in
{
  flake.modules.nixos.bittorrent-proxy =
    { config, ... }:
    {
      sops.secrets."bittorrent-proxy/password" = {
        owner = "microsocks";
        group = "microsocks";
      };

      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

      networking.firewall.allowedTCPPorts = [ 45500 ];
      networking.firewall.allowedUDPPorts = [ 45500 ];

      networking.nftables.enable = true;
      networking.nftables.ruleset = ''
        table ip nat {
          chain prerouting {
            type nat hook prerouting priority -100;
            tcp dport 45500 dnat to ${tailscaleIps.homelab}:45500
            udp dport 45500 dnat to ${tailscaleIps.homelab}:45500
          }
          chain postrouting {
            type nat hook postrouting priority 100;
            masquerade
          }
        }
      '';

      services.microsocks = {
        enable = true;
        ip = tailscaleIps.vps;
        port = 1080;
        authUsername = "sallywag";
        authPasswordFile = config.sops.secrets."bittorrent-proxy/password".path;
      };
    };
}
