{
  flake.modules.nixos.vpn =
    { config, lib, ... }:
    let
      wireguardConfs = {
        homelab = {
          ips = [
            "10.2.0.2/32"
            "2a07:b944::2:2/128"
          ];
          preSetup = ''
            ip route add 193.148.18.82/32 via 192.168.1.1 dev enp5s0 || true
            ip -6 route add 2a0d:5600:24:ff06::10/128 via fe80::2258:43ff:fe5d:e2a2 dev enp5s0 || true
          '';
          postSetup = ''
            ip route add 193.148.18.82/32 via 192.168.1.1 dev enp5s0 || true
            ip -6 route add 2a0d:5600:24:ff06::10/128 via fe80::2258:43ff:fe5d:e2a2 dev enp5s0 || true
            ip -6 route replace default dev wg0-protonvpn metric 50
            ip -6 route del default dev wg0-protonvpn metric 1024 || true
          '';
          postShutdown = ''
            ip route del 193.148.18.82/32 via 192.168.1.1 dev enp5s0 || true
            ip -6 route del 2a0d:5600:24:ff06::10/128 via fe80::2258:43ff:fe5d:e2a2 dev enp5s0 || true
            ip -6 route del default dev wg0-protonvpn metric 50 || true
          '';
          peers = [
            {
              publicKey = "R8Of+lrl8DgOQmO6kcjlX7SchP4ncvbY90MB7ZUNmD8=";
              allowedIPs = [
                "0.0.0.0/0"
                "::/0"
              ];
              endpoint = "193.148.18.82:51820";
              persistentKeepalive = 25;
            }
          ];
        };
        vps = {
          ips = [
            "10.2.0.2/32"
            "2a07:b944::2:2/128"
          ];
          preSetup = ''
            ip route add 149.88.24.180/32 via 172.31.1.1 dev enp1s0 || true
            ip -6 route add 2a0d:5600:24:ff06::10/128 via fe80::1 dev enp1s0 || true
          '';
          postSetup = ''
            ip route add 149.88.24.180/32 via 172.31.1.1 dev enp1s0 || true
            ip -6 route add 2a0d:5600:24:ff06::10/128 via fe80::1 dev enp1s0 || true
            ip -6 route replace default dev wg0-protonvpn metric 50
            ip -6 route del default dev wg0-protonvpn metric 1024 || true
          '';
          postShutdown = ''
            ip route del 149.88.24.180/32 via 172.31.1.1 dev enp1s0 || true
            ip -6 route del 2a0d:5600:24:ff06::10/128 via fe80::1 dev enp1s0 || true
            ip -6 route del default dev wg0-protonvpn metric 50 || true
          '';
          peers = [
            {
              publicKey = "dZaHVURZJIpIPz1DceHUu1QA0WCz9VYEKKey0cymHXI=";
              allowedIPs = [
                "0.0.0.0/0"
                "::/0"
              ];
              endpoint = "149.88.24.180:51820";
              persistentKeepalive = 25;
            }
          ];
        };
      };
    in
    {
      sops.secrets."wireguard-confs/protonvpn-${config.networking.hostName}-private-key" = { };

      networking = {
        wireguard.interfaces."wg0-protonvpn" = {
          privateKeyFile =
            config.sops.secrets."wireguard-confs/protonvpn-${config.networking.hostName}-private-key".path;
        }
        // wireguardConfs.${config.networking.hostName};

        nftables = lib.mkIf config.system.tailscale.enable {
          enable = true;
          tables = {
            "protonvpn-tailscale" = {
              enable = true;
              family = "inet";
              content = ''
                chain prerouting {
                  type filter hook prerouting priority -50; policy accept;

                  # Allow Tailscale protocol traffic to bypass Proton VPN
                  udp dport 41641 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;

                  # Allow direct mesh traffic (Tailscale device to Tailscale device) to bypass Proton VPN
                  ip saddr 100.64.0.0/10 ip daddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;

                  # Exit node traffic: DON'T mark it - let it route through VPN without bypass mark
                  iifname "tailscale0" ip daddr != 100.64.0.0/10 meta mark set 0;

                  # Return traffic from VPN: Mark it so it routes via Tailscale table
                  iifname "wg0-protonvpn" ip daddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
                }

                chain outgoing {
                  type route hook output priority -100; policy accept;
                  meta mark 0x80000 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
                  ip daddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
                  udp sport 41641 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;

                  # Fix Tailscale 1.96+ connmark interference with Proton VPN:
                  # Tailscale's mangle/OUTPUT rule (priority -150) saves bits 16-23 of the
                  # meta mark into the ct mark for every new connection. The Proton VPN bypass
                  # mark 0x6d6f6c65 has those bits set (& 0xff0000 = 0x6f0000), so Tailscale
                  # saves 0x006f0000 into the ct mark. Its mangle/PREROUTING rule then
                  # restores 0x006f0000 as the meta mark on incoming replies, which no longer
                  # equals the full bypass mark 0x6d6f6c65 and is dropped by Proton VPN's
                  # INPUT firewall. Setting ct mark to 0x00000f41 here (whose bits 16-23 are
                  # zero) prevents the PREROUTING restore from firing.
                  ct state new meta mark == 0x6d6f6c65 ct mark set 0x00000f41;
                }

                chain postrouting {
                  type nat hook postrouting priority 100; policy accept;

                  # Masquerade exit node traffic going through Proton VPN
                  iifname "tailscale0" oifname "wg0-protonvpn" masquerade;
                }
              '';
            };
            "protonvpn-killswitch" = {
              enable = true;
              family = "inet";
              content = ''
                chain output {
                  type filter hook output priority 0; policy drop;

                  # Allow loopback
                  oifname "lo" accept

                  # Allow Tailscale
                  oifname "tailscale0" accept

                  # Allow established/related connections
                  ct state established,related accept

                  # Allow traffic through the tunnel
                  oifname "wg0-protonvpn" accept

                  # Allow WireGuard endpoint traffic so tunnel can establish/re-establish
                  ip daddr 193.148.18.82 udp dport 51820 accept
                  ip daddr 149.88.24.180 udp dport 51820 accept
                  ip6 daddr 2a0d:5600:24:ff06::10 udp dport 51820 accept
                }
              '';
            };
          };
        };
      };
    };
}
