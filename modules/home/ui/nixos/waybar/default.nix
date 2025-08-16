{
  lib,
  config,
  theme,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ui.nixos.waybar;
in {
  meta.doc = lib.mdDoc ''
    Waybar status bar configuration for Hyprland.
    
    Provides [Waybar](https://github.com/Alexays/Waybar) with:
    - Hyprland workspace integration with click-to-activate
    - System monitoring: CPU, memory, battery, network status
    - Audio control with volume adjustment and pavucontrol integration
    - Date/time display with calendar tooltip
    - System tray for applications
    - Custom styling integrated with global theme
    - Systemd integration for proper session management
  '';

  options.ui.nixos.waybar = {
    enable = mkEnableOption (lib.mdDoc "Waybar status bar for Hyprland");
  };

  config = mkIf cfg.enable {
    ui.fonts.enable = true;

    programs.waybar = {
      enable = true;

      systemd = {
        enable = true;
        target = "hyprland-session.target";
      };

      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          mod = "dock";
          height = 48;

          modules-left = ["hyprland/workspaces"];

          modules-right = [
            "tray"
            "network"
            "pulseaudio"
            "memory"
            "cpu"
            "battery"
            "clock"
          ];

          "hyprland/workspaces" = {
            active-only = false;
            all-outputs = true;
            on-click = "activate";
            format = "{icon}";
            format-icons = {
              sort-by-number = true;
            };
          };

          tray = {
            icon-size = 15;
            spacing = 8;
          };

          network = {
            format-wifi = "  {essid} {signalStrength}%";
            format-ethernet = "󰈀";
            format-disconnected = "󰈂";
          };

          pulseaudio = {
            format = "{icon} {volume}%";
            format-muted = "󰝟";
            format-icons = {
              default = ["󰕿" "󰖀" "󰕾"];
            };
            scroll-step = 5;
            on-click = "kill $(pgrep pavucontrol) || ${pkgs.pavucontrol}/bin/pavucontrol";
          };

          memory = {
            format = "󰍛 {percentage}%";
            format-alt = "󰍛 {used}/{total} GiB";
            interval = 5;
          };

          cpu = {
            format = "󰻠 {usage}%";
            format-alt = "󰻠 {avg_frequency} GHz";
            interval = 5;
          };

          battery = {
            states = {
              good = 95;
              warning = 30;
              critical = 15;
            };
            format = "{icon}  {capacity}%";
            format-charging = "  {capacity}%";
            format-plugged = " {capacity}% ";
            format-alt = "{icon} {time}";
            format-icons = ["" "" "" "" ""];
          };

          clock = {
            format = "󰥔  {:%a, %d %b, %I:%M %p}";
            tooltip = "true";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            format-alt = "   {:%d/%m}";
          };
        };
      };

      style = import ./style.nix {inherit theme;};
    };
  };
}
