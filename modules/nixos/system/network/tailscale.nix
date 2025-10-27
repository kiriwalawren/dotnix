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

    # Mullvad VPN integration - wrap tailscaled with mullvad-exclude to bypass VPN tunnel
    systemd.services.tailscaled = mkIf config.services.mullvad-vpn.enable {
      serviceConfig.ExecStart = [
        "" # Clear previous ExecStart
        "${mullvadPkg}/bin/mullvad-exclude ${pkgs.tailscale}/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=\${PORT} $FLAGS"
      ];
    };
  };
}
