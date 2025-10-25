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

    killSwitch = {
      enable = mkEnableOption "VPN kill switch - blocks all non-Tailscale traffic when VPN is down";

      allowLocalNetwork = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to allow traffic to local network (RFC1918 addresses) when VPN is down";
      };
    };
  };

  config = mkIf cfg.enable {
    services.resolved.enable = true;
    environment.systemPackages = with pkgs; [wireguard-tools];
    sops.secrets."mullvad-private-keys/${config.networking.hostName}" = {};

    # VPN Kill Switch: Block all non-Tailscale traffic when VPN is down
    networking.firewall = mkIf cfg.killSwitch.enable {
      # Allow forwarding for Tailscale and VPN
      checkReversePath = "loose";

      extraCommands = ''
        # Flush any existing rules in the killswitch chain
        iptables -w -F nixos-vpn-killswitch 2>/dev/null || true
        iptables -w -X nixos-vpn-killswitch 2>/dev/null || true
        ip6tables -w -F nixos-vpn-killswitch 2>/dev/null || true
        ip6tables -w -X nixos-vpn-killswitch 2>/dev/null || true

        # Create killswitch chain
        iptables -w -N nixos-vpn-killswitch
        ip6tables -w -N nixos-vpn-killswitch

        # IPv4 Rules
        # Allow loopback
        iptables -w -A nixos-vpn-killswitch -o lo -j ACCEPT

        # Allow established/related connections
        iptables -w -A nixos-vpn-killswitch -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

        ${optionalString config.services.tailscale.enable ''
        # Allow traffic on Tailscale interface
        iptables -w -A nixos-vpn-killswitch -o tailscale0 -j ACCEPT
        ''}

        # Allow traffic on VPN interface
        iptables -w -A nixos-vpn-killswitch -o vpn0 -j ACCEPT

        ${optionalString cfg.killSwitch.allowLocalNetwork ''
        # Allow local network traffic (RFC1918)
        iptables -w -A nixos-vpn-killswitch -d 192.168.0.0/16 -j ACCEPT
        iptables -w -A nixos-vpn-killswitch -d 10.0.0.0/8 -j ACCEPT
        iptables -w -A nixos-vpn-killswitch -d 172.16.0.0/12 -j ACCEPT
        # Allow link-local
        iptables -w -A nixos-vpn-killswitch -d 169.254.0.0/16 -j ACCEPT
        ''}

        # Allow DHCP (for getting initial connection)
        iptables -w -A nixos-vpn-killswitch -p udp --dport 67:68 -j ACCEPT

        # Drop everything else
        iptables -w -A nixos-vpn-killswitch -j DROP

        # IPv6 Rules
        # Allow loopback
        ip6tables -w -A nixos-vpn-killswitch -o lo -j ACCEPT

        # Allow established/related connections
        ip6tables -w -A nixos-vpn-killswitch -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

        ${optionalString config.services.tailscale.enable ''
        # Allow traffic on Tailscale interface
        ip6tables -w -A nixos-vpn-killswitch -o tailscale0 -j ACCEPT
        ''}

        # Allow traffic on VPN interface
        ip6tables -w -A nixos-vpn-killswitch -o vpn0 -j ACCEPT

        ${optionalString cfg.killSwitch.allowLocalNetwork ''
        # Allow local network traffic (ULA and link-local)
        ip6tables -w -A nixos-vpn-killswitch -d fc00::/7 -j ACCEPT
        ip6tables -w -A nixos-vpn-killswitch -d fe80::/10 -j ACCEPT
        ''}

        # Allow DHCPv6
        ip6tables -w -A nixos-vpn-killswitch -p udp --dport 546:547 -j ACCEPT

        # Allow ICMPv6 (required for IPv6 to function)
        ip6tables -w -A nixos-vpn-killswitch -p ipv6-icmp -j ACCEPT

        # Drop everything else
        ip6tables -w -A nixos-vpn-killswitch -j DROP

        # Insert killswitch chain at the beginning of OUTPUT chain
        iptables -w -D OUTPUT -j nixos-vpn-killswitch 2>/dev/null || true
        iptables -w -I OUTPUT 1 -j nixos-vpn-killswitch
        ip6tables -w -D OUTPUT -j nixos-vpn-killswitch 2>/dev/null || true
        ip6tables -w -I OUTPUT 1 -j nixos-vpn-killswitch
      '';

      extraStopCommands = ''
        # Clean up killswitch rules
        iptables -w -D OUTPUT -j nixos-vpn-killswitch 2>/dev/null || true
        iptables -w -F nixos-vpn-killswitch 2>/dev/null || true
        iptables -w -X nixos-vpn-killswitch 2>/dev/null || true
        ip6tables -w -D OUTPUT -j nixos-vpn-killswitch 2>/dev/null || true
        ip6tables -w -F nixos-vpn-killswitch 2>/dev/null || true
        ip6tables -w -X nixos-vpn-killswitch 2>/dev/null || true
      '';
    };

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
