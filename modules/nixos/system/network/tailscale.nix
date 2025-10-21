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

    services.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.tailscale-auth-key.path;
      openFirewall = true;
      useRoutingFeatures =
        if cfg.mode == "server"
        then "both"
        else "client";
      extraUpFlags =
        (optionals (cfg.mode == "server") ["--advertise-exit-node"])
        ++ (optionals cfg.vpn.enable ["--exit-node=${cfg.vpn.exitNode}"]);
    };
  };
}
