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

    systemd.services.mullvad-select = {
      description = "Select nearest Mullvad server and bring up WireGuard";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        Environment = [
          "PRIVATE_KEY_FILE=${config.sops.secrets."mullvad-private-keys/${config.networking.hostName}".path}"
          "MEASURE_METHOD=ping"
          "VPN_ADDRESS=${inputs.secrets.mullvad."${config.networking.hostName}".address}"
          "VPN_DNS=${concatStringsSep "," cfg.dns}"
        ];
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /etc/wireguard";
        ExecStart = "${myScript}/bin/mullvad-select";
        ExecStop = "${pkgs.wireguard-tools}/bin/wg-quick down vpn0";
        CacheDirectory = "mullvad";
        RemainAfterExit = true;
      };
    };

    systemd.timers.mullvad-select-timer = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitActiveSec = "10m"; # re-evaluate every 10 minutes
        Unit = "mullvad-select.service";
      };
    };

    services.tailscale.extraUpFlags = ["--accept-routes=false"];
  };
}
