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

    # Exclude Tailscale traffic from VPN by adding routing rules
    # Policy routing: send Tailscale IPs to Tailscale's table (52) before VPN catches them
    # Must use priority LOWER than VPN's 5099 rule (lower number = higher priority)
    networking.firewall.extraCommands = mkIf config.services.tailscale.enable ''
      # Add rules with priority 5050/5051 (before VPN's 5099) to route Tailscale traffic outside the tunnel
      ${pkgs.iproute2}/bin/ip rule del to 100.64.0.0/10 lookup 52 priority 5050 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip rule add to 100.64.0.0/10 lookup 52 priority 5050
      ${pkgs.iproute2}/bin/ip rule del from 100.64.0.0/10 lookup 52 priority 5051 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip rule add from 100.64.0.0/10 lookup 52 priority 5051
    '';

    networking.firewall.extraStopCommands = mkIf config.services.tailscale.enable ''
      # Clean up routing rules when firewall stops
      ${pkgs.iproute2}/bin/ip rule del to 100.64.0.0/10 lookup 52 priority 5050 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip rule del from 100.64.0.0/10 lookup 52 priority 5051 2>/dev/null || true
    '';

    systemd.services.mullvad-select = {
      description = "Select nearest Mullvad server and bring up WireGuard";
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
        ExecStop = "-${pkgs.wireguard-tools}/bin/wg-quick down vpn0";
        RemainAfterExit = true;
        CacheDirectory = "mullvad";
      };
    };

    # runner service that simply executes the script (no ExecStop)
    systemd.services.mullvad-select-run = {
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

    # timer that triggers the runner (use OnCalendar or OnUnitActiveSec/OnActiveSec)
    systemd.timers.mullvad-select-run = {
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

    services.tailscale.extraUpFlags = ["--accept-routes=false"];
  };
}
