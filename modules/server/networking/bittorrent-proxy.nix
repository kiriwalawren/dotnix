{ config, ... }:
{
  flake.modules.nixos.bittorrent-proxy = {
    sops.secrets."bittorrent-proxy/password" = { };

    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    networking.firewall.allowedTCPPorts = [ 45500 ];
    networking.firewall.allowedUDPPorts = [ 45500 ];

    networking.nftables.enable = true;
    networking.nftables.ruleset = ''
      table ip nat {
        chain prerouting {
          type nat hook prerouting priority -100;
          tcp dport 45500 dnat to ${config.tailscale.ips.homelab}:45500
          udp dport 45500 dnat to ${config.tailscale.ips.homelab}:45500
        }
        chain postrouting {
          type nat hook postrouting priority 100;
          masquerade
        }
      }
    '';

    services.microsocks = {
      enable = true;
      ip = config.tailscale.ips.vps;
      port = 1080;
      authUsername = "sallywag";
      authPasswordFile = config.sops.secrets."bittorrent-proxy/password".path;
    };
  };
}
