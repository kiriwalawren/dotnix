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

        systemd.services.tailscaled = {
          after = optional config.services.adguardhome.enable "adguardhome.service";
          requires = optional config.services.adguardhome.enable "adguardhome.service";
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
      };
    };

  flake.modules.nixos.tailscale-server-mode.system.tailscale.mode = "server";
}
