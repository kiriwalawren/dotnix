{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
with lib; let
  cfg = config.system.vpn;

  myScript = pkgs.writeShellApplication {
    name = "mullvad-select";
    runtimeInputs = with pkgs; [curl jq wireguard-tools iproute2 coreutils findutils iputils gawk];
    text = builtins.readFile ./mullvad-select.sh;
  };
in {
  options.system.vpn = {
    enable = mkEnableOption "vpn";

    dns = mkOption {
      type = types.listOf types.str;
      default = ["194.242.2.4"];
      example = ["194.242.2.4"];
      description = "DNS servers to use with the VPN. Defaults to Mullvad's base DNS (blocks ads, trackers, and malware).";
    };
  };

  config = mkIf cfg.enable {
    services.resolved.enable = true;
    environment.systemPackages = with pkgs; [wireguard-tools];
    sops.secrets."mullvad-private-keys/${config.networking.hostName}" = {};

    systemd = {
      services = {
        mullvad-select = {
          description = "Select nearest Mullvad server and bring up WireGuard";
          wantedBy = ["multi-user.target"];
          wants = ["network-online.target" "nss-lookup.target" "mullvad-select-run.timer"];
          after = ["network-online.target" "nss-lookup.target"];
          serviceConfig = {
            Type = "oneshot";
            Environment = [
              "PRIVATE_KEY_FILE=${config.sops.secrets."mullvad-private-keys/${config.networking.hostName}".path}"
              "MEASURE_METHOD=ping"
              "VPN_ADDRESS=${inputs.secrets.mullvad."${config.networking.hostName}".address}"
              "VPN_DNS=${concatStringsSep "," cfg.dns}"
            ];
            ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /etc/wireguard";
            ExecStart = "${pkgs.util-linux}/bin/flock -n /run/lock/mullvad-select.lock ${myScript}/bin/mullvad-select";
            ExecStartPost = mkIf config.services.tailscale.enable (pkgs.writeShellScript "add-tailscale-routes" ''
              # Add routing rules to exclude Tailscale traffic from VPN
              # See: https://tailscale.com/kb/1082/firewall-ports

              # Exclude Tailscale peer traffic (CGNAT range)
              ${pkgs.iproute2}/bin/ip rule del to 100.64.0.0/10 lookup 52 priority 5050 2>/dev/null || true
              ${pkgs.iproute2}/bin/ip rule add to 100.64.0.0/10 lookup 52 priority 5050
              ${pkgs.iproute2}/bin/ip rule del from 100.64.0.0/10 lookup 52 priority 5051 2>/dev/null || true
              ${pkgs.iproute2}/bin/ip rule add from 100.64.0.0/10 lookup 52 priority 5051

              # Exclude Tailscale control plane & DERP servers (IPv4)
              ${pkgs.iproute2}/bin/ip rule del to 192.200.0.0/24 lookup 52 priority 5052 2>/dev/null || true
              ${pkgs.iproute2}/bin/ip rule add to 192.200.0.0/24 lookup 52 priority 5052
              ${pkgs.iproute2}/bin/ip rule del to 199.165.136.0/24 lookup 52 priority 5053 2>/dev/null || true
              ${pkgs.iproute2}/bin/ip rule add to 199.165.136.0/24 lookup 52 priority 5053

              # Exclude Tailscale control plane & DERP servers (IPv6)
              ${pkgs.iproute2}/bin/ip -6 rule del to 2606:b740:49::/48 lookup 52 priority 5054 2>/dev/null || true
              ${pkgs.iproute2}/bin/ip -6 rule add to 2606:b740:49::/48 lookup 52 priority 5054
              ${pkgs.iproute2}/bin/ip -6 rule del to 2606:b740:1::/48 lookup 52 priority 5055 2>/dev/null || true
              ${pkgs.iproute2}/bin/ip -6 rule add to 2606:b740:1::/48 lookup 52 priority 5055
            '');
            ExecStop = mkIf config.services.tailscale.enable (pkgs.writeShellScript "stop-vpn" ''
              # Remove Tailscale routing rules
              ${pkgs.iproute2}/bin/ip rule del to 100.64.0.0/10 lookup 52 priority 5050 2>/dev/null || true
              ${pkgs.iproute2}/bin/ip rule del from 100.64.0.0/10 lookup 52 priority 5051 2>/dev/null || true
              ${pkgs.iproute2}/bin/ip rule del to 192.200.0.0/24 lookup 52 priority 5052 2>/dev/null || true
              ${pkgs.iproute2}/bin/ip rule del to 199.165.136.0/24 lookup 52 priority 5053 2>/dev/null || true
              ${pkgs.iproute2}/bin/ip -6 rule del to 2606:b740:49::/48 lookup 52 priority 5054 2>/dev/null || true
              ${pkgs.iproute2}/bin/ip -6 rule del to 2606:b740:1::/48 lookup 52 priority 5055 2>/dev/null || true
              # Bring down VPN
              ${pkgs.wireguard-tools}/bin/wg-quick down vpn0 || true
            '');
            RemainAfterExit = true;
            Restart = "on-failure";
            RestartSec = "5s";
            CacheDirectory = "mullvad";
          };
        };

        # runner service that simply executes the script (no ExecStop)
        mullvad-select-run = {
          description = "Run mullvad-select script (periodic runner)";
          partOf = ["mullvad-select.service"];
          wants = ["network-online.target" "nss-lookup.target"];
          after = ["network-online.target" "nss-lookup.target"];
          serviceConfig = {
            Type = "oneshot";
            Environment = [
              "PRIVATE_KEY_FILE=${config.sops.secrets."mullvad-private-keys/${config.networking.hostName}".path}"
              "MEASURE_METHOD=ping"
              "VPN_ADDRESS=${inputs.secrets.mullvad."${config.networking.hostName}".address}"
              "VPN_DNS=${concatStringsSep "," cfg.dns}"
            ];
            ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /etc/wireguard";
            ExecStart = "${pkgs.util-linux}/bin/flock -n /run/lock/mullvad-select.lock ${myScript}/bin/mullvad-select";
            RemainAfterExit = "no"; # runner should exit so timer scheduling is sane
            # no ExecStop so it won't take down wg
            CacheDirectory = "mullvad";
          };
        };
      };

      # timer that triggers the runner (use OnCalendar or OnUnitActiveSec/OnActiveSec)
      timers.mullvad-select-run = {
        wantedBy = ["timers.target"];
        partOf = ["mullvad-select.service"];
        timerConfig = {
          OnBootSec = "30s";
          # Use OnActiveSec (relative to the timer itself) or OnCalendar for wall-clock schedule.
          # OnActiveSec will schedule every N after the runner finishes — good for periodic runs.
          OnActiveSec = "10m";
          AccuracySec = "1m";
          Unit = "mullvad-select-run.service";
          Persistent = true;
        };
      };
    };

    services.tailscale.extraUpFlags = ["--accept-routes=false"];
    systemd.services.tailscaled.after = ["mullvad-select.service"];
  };
}
