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
        ++ (optionals cfg.vpn.enable ["--exit-node=${cfg.vpn.exitNode}"])
        ++ (optionals config.services.mullvad-vpn.enable ["--accept-routes=false"]);
    };

    # Mullvad VPN integration - ensure Tailscale is excluded from VPN tunnel
    systemd.services = mkIf config.services.mullvad-vpn.enable {
      # Ensure Mullvad waits for Tailscale to start before configuring and connecting
      mullvad-config = {
        wants = ["tailscaled.service" "tailscaled-autoconnect.service"];
        after = ["tailscaled.service" "tailscaled-autoconnect.service"];
      };

      # Ensure tailscaled upholds the split-tunnel service
      tailscaled.upholds = ["mullvad-split-tunnel-tailscale.service"];

      # Configure split-tunnel for Tailscale
      mullvad-split-tunnel-tailscale = {
        description = "Add Tailscale to Mullvad split-tunnel";
        after = ["tailscaled.service" "mullvad-config.service"];
        bindsTo = ["tailscaled.service"]; # Stop when tailscaled stops
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "mullvad-split-tunnel-tailscale-start" ''
            # Wait for tailscaled to be fully running
            for i in {1..30}; do
              if ${pkgs.systemd}/bin/systemctl is-active tailscaled.service &>/dev/null; then
                break
              fi
              sleep 1
            done

            # Get tailscaled PID
            TAILSCALE_PID=$(${pkgs.systemd}/bin/systemctl show -p MainPID --value tailscaled.service)

            if [ -n "$TAILSCALE_PID" ] && [ "$TAILSCALE_PID" != "0" ]; then
              echo "Adding Tailscale (PID: $TAILSCALE_PID) to Mullvad split-tunnel"
              ${mullvadPkg}/bin/mullvad split-tunnel pid add "$TAILSCALE_PID" || true
              # Store PID for cleanup
              echo "$TAILSCALE_PID" > /run/mullvad-split-tunnel-tailscale.pid
            else
              echo "Warning: Could not determine Tailscale PID"
            fi
          '';
          ExecStop = pkgs.writeShellScript "mullvad-split-tunnel-tailscale-stop" ''
            # Remove old PID from split-tunnel
            if [ -f /run/mullvad-split-tunnel-tailscale.pid ]; then
              OLD_PID=$(cat /run/mullvad-split-tunnel-tailscale.pid)
              if [ -n "$OLD_PID" ]; then
                echo "Removing old Tailscale PID ($OLD_PID) from Mullvad split-tunnel"
                ${mullvadPkg}/bin/mullvad split-tunnel pid delete "$OLD_PID" || true
              fi
              rm -f /run/mullvad-split-tunnel-tailscale.pid
            fi
          '';
        };
      };
    };
  };
}
