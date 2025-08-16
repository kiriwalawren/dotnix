{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.system.protonvpn;
  hostname = config.networking.hostName;
in {
  options.system.protonvpn = {
    enable = mkEnableOption "ProtonVPN configuration";

    serverEndpoint = mkOption {
      type = types.str;
      default = "146.70.183.18:51820";
      description = "ProtonVPN WireGuard server endpoint (IP:port)";
    };

    serverPublicKey = mkOption {
      type = types.str;
      default = "wm+NrCihayTi0RbmaW4CWZI3h9KOU/i7320UyTY4zFc=";
      description = "ProtonVPN server public key (must match serverEndpoint)";
    };

    autoStart = mkOption {
      type = types.bool;
      default = false;
      description = "Automatically start VPN on boot";
    };

    killSwitch = mkOption {
      type = types.bool;
      default = true;
      description = "Enable kill switch to block traffic when VPN is down";
    };

    clientIP = mkOption {
      type = types.str;
      default = "10.2.0.2/32";
      description = "Client IP address assigned by ProtonVPN";
    };

    clientIPv6 = mkOption {
      type = types.str;
      default = "2a07:b944::2:2/128";
      description = ''
        Client IPv6 address used by ProtonVPN.

        NOTE: Only ~80% of ProtonVPN servers support IPv6. When implementing
        automatic server selection, ensure only IPv6-capable servers are selected
        when system IPv6 is enabled to prevent leaks.
      '';
    };

    dnsIPv6 = mkOption {
      type = types.str;
      default = "2a07:b944::2:1";
      description = "ProtonVPN IPv6 DNS server address";
    };
  };

  config = mkIf cfg.enable {
    # Assertion to ensure required secrets exist
    assertions = [
      {
        assertion = config.sops.secrets ? "protonvpn/${hostname}/private_key";
        message = "ProtonVPN private key for host '${hostname}' not found in sops secrets. Expected: protonvpn/${hostname}/private_key";
      }
    ];

    networking = {
      firewall = {
        checkReversePath = "loose";
        allowedUDPPorts = [51820];
      };

      # WireGuard configuration
      wireguard = {
        enable = true;
        interfaces.protonvpn = {
          ips = [cfg.clientIP] ++ optionals config.networking.enableIPv6 [cfg.clientIPv6];
          privateKeyFile = config.sops.secrets."protonvpn/${hostname}/private_key".path;

          peers = [
            {
              publicKey = cfg.serverPublicKey;
              endpoint = cfg.serverEndpoint;
              allowedIPs = ["0.0.0.0/0" "::/0"];
              persistentKeepalive = 25;
            }
          ];

          postSetup =
            ''
              # Add host route for VPN server to prevent routing loop
              VPN_SERVER_IP=${builtins.head (builtins.split ":" cfg.serverEndpoint)}
              DEFAULT_GW=$(${pkgs.iproute2}/bin/ip route show default | ${pkgs.gnugrep}/bin/grep -oP 'via \K[^\s]+' | head -1)
              DEFAULT_DEV=$(${pkgs.iproute2}/bin/ip route show default | ${pkgs.gnugrep}/bin/grep -oP 'dev \K[^\s]+' | head -1)
              ${pkgs.iproute2}/bin/ip route add $VPN_SERVER_IP via $DEFAULT_GW dev $DEFAULT_DEV 2>/dev/null || true
              
              # Set up routing for ProtonVPN
              ${pkgs.iproute2}/bin/ip route add default dev protonvpn table 200
              ${pkgs.iproute2}/bin/ip rule add from ${builtins.head (builtins.split "/" cfg.clientIP)} table 200

              ${optionalString config.networking.enableIPv6 ''
                # Set up IPv6 routing with higher priority than router
                ${pkgs.iproute2}/bin/ip -6 route add default dev protonvpn table 200
                ${pkgs.iproute2}/bin/ip -6 rule add from ${builtins.head (builtins.split "/" cfg.clientIPv6)} table 200
                
                # Override main table default route with higher priority VPN route
                ${pkgs.iproute2}/bin/ip -6 route add default dev protonvpn metric 100
              ''}

              # Set DNS to ProtonVPN's DNS servers
              ${pkgs.openresolv}/bin/resolvconf -a protonvpn <<EOF
              nameserver 10.2.0.1
              ${optionalString config.networking.enableIPv6 "nameserver ${cfg.dnsIPv6}"}
              EOF

            ''
            + optionalString cfg.killSwitch ''
              # Kill switch - block traffic if VPN is down
              ${pkgs.iptables}/bin/iptables -I OUTPUT ! -o protonvpn -m mark ! --mark $(${pkgs.wireguard-tools}/bin/wg show protonvpn fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
              ${pkgs.iptables}/bin/ip6tables -I OUTPUT ! -o protonvpn -m mark ! --mark $(${pkgs.wireguard-tools}/bin/wg show protonvpn fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
            '';

          postShutdown =
            ''
              # Clean up routing
              ${pkgs.iproute2}/bin/ip rule del from ${builtins.head (builtins.split "/" cfg.clientIP)} table 200 2>/dev/null || true
              ${pkgs.iproute2}/bin/ip route del default dev protonvpn table 200 2>/dev/null || true
              
              ${optionalString config.networking.enableIPv6 ''
                # Clean up IPv6 routing
                ${pkgs.iproute2}/bin/ip -6 rule del from ${builtins.head (builtins.split "/" cfg.clientIPv6)} table 200 2>/dev/null || true
                ${pkgs.iproute2}/bin/ip -6 route del default dev protonvpn table 200 2>/dev/null || true
                ${pkgs.iproute2}/bin/ip -6 route del default dev protonvpn metric 100 2>/dev/null || true
              ''}

              # Reset DNS
              ${pkgs.openresolv}/bin/resolvconf -d protonvpn

            ''
            + optionalString cfg.killSwitch ''
              # Remove kill switch rules
              ${pkgs.iptables}/bin/iptables -D OUTPUT ! -o protonvpn -m mark ! --mark $(${pkgs.wireguard-tools}/bin/wg show protonvpn fwmark) -m addrtype ! --dst-type LOCAL -j REJECT 2>/dev/null || true
              ${pkgs.iptables}/bin/ip6tables -D OUTPUT ! -o protonvpn -m mark ! --mark $(${pkgs.wireguard-tools}/bin/wg show protonvpn fwmark) -m addrtype ! --dst-type LOCAL -j REJECT 2>/dev/null || true
            '';
        };
      };
    };

    # Secrets configuration
    sops.secrets = {
      "protonvpn/${hostname}/private_key" = {
        mode = "0400";
        owner = "root";
        group = "root";
      };
    };

    environment.systemPackages = with pkgs; [
      wireguard-tools
    ];


    systemd.services.wireguard-protonvpn = mkIf cfg.autoStart {
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
    };
  };
}
