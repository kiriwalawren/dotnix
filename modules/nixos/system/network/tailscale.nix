{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.system.tailscale;
  mullvadPkg = config.services.mullvad-vpn.package;
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

    # Mullvad VPN integration - ensure Tailscale is excluded from VPN tunnel
    networking.nftables = mkIf config.services.mullvad-vpn.enable {
      enable = true;

      tables = {
        tailscale_mullvad = {
          type = "inet";

          chains = {
            mangle_output = {
              type = "route";
              hook = "output";
              priority = -150;
              policy = "accept";
              rules = ''
                # Mark all packets destined for Tailscale subnet
                ip daddr 100.64.0.0/10 meta mark set 0x40000
              '';
            };

            allow_tunnels = {
              type = "filter";
              hook = "output";
              priority = 0;
              policy = "accept";
              rules = ''
                # Allow packets to Tailscale or Mullvad interfaces
                oifname "tailscale0" accept
                oifname "wg-mullvad" accept
                oifname "lo" accept

                # Drop everything else if killswitch is active
                # drop
              '';
            };
          };
        };
      };
    };
  };
}
