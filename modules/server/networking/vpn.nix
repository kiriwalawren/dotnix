{
  flake.modules.nixos.base =
    { config, lib, ... }:
    let
      wgConfs = {
        homelab = {
          addresses = [
            "10.2.0.2/32"
            "2a07:b944::2:2/128"
          ];
          endpoints = {
            ipv4 = "193.148.18.82";
            ipv6 = "2a0d:5600:24:ff06::10";
          };
          gateways = {
            ipv4 = "192.168.1.1";
            ipv6 = "fe80::2258:43ff:fe5d:e2a2";
          };
          network = "enp5s0";
          peer = {
            publicKey = "R8Of+lrl8DgOQmO6kcjlX7SchP4ncvbY90MB7ZUNmD8=";
          };
        };
      };

      mkWireguard = host: {
        ips = wgConfs.${host}.addresses;
        preSetup = ''
          ip route add ${wgConfs.${host}.endpoints.ipv4}/32 via ${wgConfs.${host}.gateways.ipv4} dev ${wgConfs.${host}.network} || true
          ip -6 route add ${wgConfs.${host}.endpoints.ipv6}/128 via ${wgConfs.${host}.gateways.ipv6} dev ${wgConfs.${host}.network} || true
        '';
        postSetup = ''
          ip route add ${wgConfs.${host}.endpoints.ipv4}/32 via ${wgConfs.${host}.gateways.ipv4} dev ${wgConfs.${host}.network} || true
          ip -6 route add ${wgConfs.${host}.endpoints.ipv6}/128 via ${wgConfs.${host}.gateways.ipv6} dev ${wgConfs.${host}.network} || true
          ip -6 route replace default dev wg0-protonvpn metric 50
          ip -6 route del default dev wg0-protonvpn metric 1024 || true
        '';
        postShutdown = ''
          ip route del ${wgConfs.${host}.endpoints.ipv4}/32 via ${wgConfs.${host}.gateways.ipv4} dev ${wgConfs.${host}.network} || true
          ip -6 route del ${wgConfs.${host}.endpoints.ipv6}/128 via ${wgConfs.${host}.gateways.ipv6} dev ${wgConfs.${host}.network} || true
          ip -6 route del default dev wg0-protonvpn metric 50 || true
        '';
        peers = [
          {
            inherit (wgConfs.${host}.peer) publicKey;
            allowedIPs = [
              "0.0.0.0/0"
              "::/0"
            ];
            endpoint = "${wgConfs.${host}.endpoints.ipv4}:51820";
            persistentKeepalive = 25;
          }
        ];
      };
    in
    {
      options.system.vpn = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };

      config = lib.mkIf config.system.vpn.enable {
        sops.secrets."wireguard-confs/protonvpn-${config.networking.hostName}-private-key" = { };

        networking = {
          wireguard.interfaces."wg0-protonvpn" = mkWireguard config.networking.hostName // {
            privateKeyFile =
              config.sops.secrets."wireguard-confs/protonvpn-${config.networking.hostName}-private-key".path;
          };

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
                    ip daddr ${wgConfs.${config.networking.hostName}.endpoints.ipv4} udp dport 51820 accept
                    ip6 daddr ${wgConfs.${config.networking.hostName}.endpoints.ipv6} udp dport 51820 accept
                  }
                '';
              };
            };
          };
        };
      };
    };
}
