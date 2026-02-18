{
  lib,
  config,
  theme,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.ui.nixos.waybar;
in
{
  options.ui.nixos.waybar = {
    enable = mkEnableOption "waybar";
  };

  config = mkIf cfg.enable {
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
          height = 26;
          spacing = 0;

          modules-left = [ "hyprland/workspaces" ];

          modules-center = [ "clock" ];

          modules-right = [
            "tray"
            "bluetooth"
            "network"
            "pulseaudio"
            "cpu"
            "memory"
            "power-profiles-daemon"
            "battery"
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
            format-wifi = "   {signalStrength}%";
            format-ethernet = "󰈀";
            format-disconnected = "󰈂";
          };

          pulseaudio = {
            format = "{format_source} {icon}  {volume}%";
            format-muted = "{format_source} 󰝟";
            format-icons = {
              default = [
                "󰕿"
                "󰖀"
                "󰕾"
              ];
            };
            format-source-muted = "󰍭";
            format-source = "󰍬";
            scroll-step = 5;
          };

          cpu = {
            format = "󰻠  {usage}%";
            format-alt = "󰻠  {avg_frequency} GHz";
            interval = 5;
          };

          memory = {
            format = "󰍛  {percentage}%";
            format-alt = "󰍛  {used}G/{total}G";
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
            format-plugged = "  {capacity}% ";
            format-alt = "{icon}  {time}";
            format-icons = [
              ""
              ""
              ""
              ""
              ""
            ];
          };

          clock = {
            format = "{:%a %b%e, %I:%M %p}";
            tooltip = "true";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          };
          bluetooth = {
            format = "";
            format-disabled = "";
            format-connected = " {num_connections}";
            tooltip-format = "{controller_alias}\t{controller_address}";
            tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
            tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
            on-click = "${pkgs.blueman}/bin/blueman-manager";
          };

          "power-profiles-daemon" = {
            format = "{icon}";
            tooltip-format = "Power profile: {profile}\nDriver: {driver}";
            tooltip = true;
            format-icons = {
              default = "󰓅";
              performance = "󰓅";
              balanced = "󰾅";
              power-saver = "󰾆";
            };
          };
        };
      };

      style = import ./style.nix { inherit theme; };
    };
  };
}
