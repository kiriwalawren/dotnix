{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.system.vpn;
  mullvadPkg =
    if cfg.gui.enable
    then pkgs.mullvad-vpn
    else pkgs.mullvad;
in {
  options.system.vpn = {
    enable = mkEnableOption "Mullvad VPN";

    gui = {
      enable = mkEnableOption "Mullvad GUI application";
    };

    location = mkOption {
      type = types.listOf types.str;
      default = ["us" "nyc"];
      example = ["se" "got"];
      description = ''
        Mullvad server location as a list of arguments.
        Format: [country city] or [country] (e.g., ["us" "nyc"], ["se" "got"], ["us"]).
        Use "mullvad relay list" to see available locations.
      '';
    };

    dns = mkOption {
      type = types.listOf types.str;
      default = ["94.140.14.14" "94.140.15.15"];
      example = ["194.242.2.4" "194.242.2.3"];
      description = ''
        DNS servers to use with the VPN.
        Defaults to AdGuard DNS (blocks ads, trackers, and malware).
      '';
    };

    autoConnect = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically connect to VPN on startup";
    };

    killSwitch = {
      enable = mkEnableOption "VPN kill switch (lockdown mode) - blocks all traffic when VPN is down";

      allowLan = mkOption {
        type = types.bool;
        default = true;
        description = "Allow LAN traffic when VPN is down (only effective with kill switch enabled)";
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable systemd-resolved (required by Mullvad VPN)
    services.resolved.enable = true;

    # Configure SOPS secret for Mullvad account number
    sops.secrets.mullvad-account-number = {};

    # Enable Mullvad VPN service
    services.mullvad-vpn = {
      enable = true;
      enableExcludeWrapper = false; # Use split-tunnel command instead for better security
      package = mullvadPkg;
    };

    # Configure Mullvad VPN settings via CLI
    systemd.services.mullvad-config = {
      description = "Configure Mullvad VPN settings";
      wantedBy = ["multi-user.target"];
      wants = ["mullvad-daemon.service" "network-online.target"];
      after = ["mullvad-daemon.service" "network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "configure-mullvad" ''
          # Wait for daemon to be ready
          for i in {1..30}; do
            if ${mullvadPkg}/bin/mullvad status &>/dev/null; then
              break
            fi
            sleep 1
          done

          # Authenticate with Mullvad account
          if ${mullvadPkg}/bin/mullvad account get | grep -q "Not logged in"; then
            echo "Logging in to Mullvad account..."
            ACCOUNT_NUMBER=$(cat ${config.sops.secrets.mullvad-account-number.path})
            ${mullvadPkg}/bin/mullvad account login "$ACCOUNT_NUMBER"
          fi

          # Configure DNS
          ${mullvadPkg}/bin/mullvad dns set custom ${concatStringsSep " " cfg.dns}

          # Configure kill switch (lockdown mode)
          ${optionalString cfg.killSwitch.enable ''
            ${mullvadPkg}/bin/mullvad lockdown-mode set on
            ${mullvadPkg}/bin/mullvad lan set ${
              if cfg.killSwitch.allowLan
              then "allow"
              else "block"
            }
          ''}
          ${optionalString (!cfg.killSwitch.enable) ''
            ${mullvadPkg}/bin/mullvad lockdown-mode set off
          ''}

          # Configure relay location
          ${mullvadPkg}/bin/mullvad relay set location ${escapeShellArgs cfg.location}

          # Auto-connect if enabled
          ${optionalString cfg.autoConnect ''
            ${mullvadPkg}/bin/mullvad auto-connect set on
            ${mullvadPkg}/bin/mullvad connect
          ''}
          ${optionalString (!cfg.autoConnect) ''
            ${mullvadPkg}/bin/mullvad auto-connect set off
          ''}
        '';
        ExecStop = pkgs.writeShellScript "logout-mullvad" ''
          # Disconnect and logout to free up device slot
          ${mullvadPkg}/bin/mullvad disconnect || true
          ${mullvadPkg}/bin/mullvad account logout || true
        '';
      };
    };
  };
}
