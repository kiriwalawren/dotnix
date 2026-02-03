{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.system.tailscale;
in {
  options.system.tailscale = {
    enable = mkEnableOption "tailscale";

    mode = mkOption {
      type = types.enum ["client" "server"];
      default = "client";
      description = ''
        Tailscale mode:
        - client: Regular Tailscale node (useRoutingFeatures = "client")
        - server: Exit node that advertises itself (useRoutingFeatures = "both" + --advertise-exit-node)
      '';
    };

    vpn = {
      enable = mkEnableOption "use Tailscale exit node for VPN";

      exitNode = mkOption {
        type = types.str;
        default = "home-server.ruffe-locrian.ts.net.";
        description = "The Tailscale exit node to use (fully qualified domain name)";
      };
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.tailscale-auth-key = {};
    networking.firewall.trustedInterfaces = ["tailscale0"];

    services = {
      # resolved prevent DNS fighting between tailscale and NetworkManager
      resolved.enable = true;
      tailscale = {
        enable = true;
        authKeyFile = config.sops.secrets.tailscale-auth-key.path;
        openFirewall = true;
        useRoutingFeatures =
          if cfg.mode == "server"
          then "both"
          else "client";
        extraUpFlags =
          (optionals (cfg.mode == "server") ["--advertise-exit-node"])
          ++ [
            "--accept-routes=false"
            "--exit-node=${
              if cfg.vpn.enable
              then cfg.vpn.exitNode
              else ""
            }"
          ];
      };
    };

    # Mullvad VPN integration - use nftables to route Tailscale traffic around VPN
    networking.nftables = mkIf config.services.mullvad-vpn.enable {
      enable = true;
      tables."mullvad-tailscale" = {
        family = "inet";
        content = ''
          chain prerouting {
            type filter hook prerouting priority -50; policy accept;

            # Allow Tailscale protocol traffic to bypass Mullvad
            udp dport 41641 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;

            # Allow direct mesh traffic (Tailscale device to Tailscale device) to bypass Mullvad
            ip saddr 100.64.0.0/10 ip daddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;

            # Exit node traffic: DON'T mark it - let it route through VPN without bypass mark
            # Clear meta mark so it routes through Mullvad (no ct mark means Mullvad won't drop in NAT)
            iifname "tailscale0" ip daddr != 100.64.0.0/10 meta mark set 0;

            # Return traffic from VPN: Mark it so it routes via Tailscale table
            # Use bypass mark so it doesn't get routed back through Mullvad
            iifname "wg0-mullvad" ip daddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
          }

          chain outgoing {
            type route hook output priority -100; policy accept;
            meta mark 0x80000 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
            ip daddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
            # Allow outgoing UDP from Tailscale port to bypass Mullvad
            udp sport 41641 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
          }

          chain postrouting {
            type nat hook postrouting priority 100; policy accept;

            # Masquerade exit node traffic going through Mullvad
            iifname "tailscale0" oifname "wg0-mullvad" masquerade;
          }
        '';
      };
    };
  };
}
