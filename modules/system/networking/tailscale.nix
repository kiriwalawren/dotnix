{ config, ... }:
let
  user = config.user.name;
in
{
  flake.modules.nixos.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    with lib;
    let
      cfg = config.system.tailscale;
      authKeySecret =
        if cfg.login-server == null then
          (if cfg.ephemeral then "tailscale-ephemeral-auth-key" else "tailscale-auth-key")
        else
          (if cfg.ephemeral then "headscale-ephemeral-auth-key" else "headscale-auth-key");
    in
    {
      options.system.tailscale = {
        enable = mkOption {
          type = lib.types.bool;
          default = true;
        };

        login-server = mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "https://headscale.walawren.com";
          description = "The URL of the control server. Leave `null` to default to Tailscale.";
        };

        mode = mkOption {
          type = types.enum [
            "client"
            "server"
          ];
          default = "client";
          description = ''
            Tailscale mode:
            - client: Regular Tailscale node (useRoutingFeatures = "client")
            - server: Exit node that advertises itself (useRoutingFeatures = "both" + --advertise-exit-node)
          '';
        };

        ephemeral = mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether this is an ephemeral node (adds --force-reauth)";
        };

        vpn = {
          enable = mkEnableOption "use Tailscale exit node for VPN";

          exitNode = mkOption {
            type = types.str;
            default = "homelab.walawren.hs.net.";
            description = "The Tailscale exit node to use (fully qualified domain name)";
          };
        };
      };

      config = mkIf cfg.enable {
        sops.secrets.${authKeySecret} = { };
        networking.firewall.trustedInterfaces = [ "tailscale0" ];

        services = {
          # resolved prevent DNS fighting between tailscale and NetworkManager
          resolved.enable = true;
          tailscale = {
            enable = true;
            authKeyFile = config.sops.secrets.${authKeySecret}.path;
            openFirewall = true;
            useRoutingFeatures = if cfg.mode == "server" then "both" else "client";
            extraUpFlags = [
              "--accept-routes=false"
              "--exit-node=${if cfg.vpn.enable then cfg.vpn.exitNode else ""}"
            ]
            ++ optional (cfg.mode == "server") "--advertise-exit-node"
            ++ optional (cfg.login-server != null) "--login-server=${cfg.login-server}"
            ++ optional cfg.ephemeral "--force-reauth";
          };
        };

        systemd.services.tailscale-operator = {
          description = "Set Tailscale operator";
          after = [ "tailscaled.service" ];
          wants = [ "tailscaled.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${lib.getExe pkgs.tailscale} set --operator=${user}";
            RemainAfterExit = true;
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
    };

  flake.modules.nixos.tailscale-server-mode.system.tailscale.mode = "server";
}
