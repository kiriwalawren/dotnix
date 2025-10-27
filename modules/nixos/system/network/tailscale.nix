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
        default = "virtualbox";
        description = "The Tailscale exit node to use";
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
          ++ (optionals cfg.vpn.enable ["--exit-node=${cfg.vpn.exitNode}"])
          ++ ["--accept-routes=false"];
      };
    };

    # Mullvad VPN integration - use nftables to route Tailscale traffic around VPN
    networking.nftables = mkIf config.services.mullvad-vpn.enable {
      enable = true;
      tables."mullvad-tailscale" = {
        family = "inet";
        content = ''
          chain prerouting {
            type filter hook prerouting priority -100; policy accept;
            ip saddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
          }

          chain outgoing {
            type route hook output priority -100; policy accept;
            meta mark 0x80000 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
            ip daddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
          }
        '';
      };
    };
  };
}
