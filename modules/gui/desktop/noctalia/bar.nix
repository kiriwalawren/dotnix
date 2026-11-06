{
  flake.wrappers.noctalia =
    { lib, pkgs, ... }:
    let
      wiremix = "exec pkill wiremix || ${lib.getExe pkgs.kitty} --class=wiremix ${lib.getExe pkgs.wiremix}";
    in
    {
      settings = {
        bar.default = {
          position = "top";
          margin_edge = 4;
          margin_ends = 4;
          capsule = true;
          capsule_opacity = 1.0;
          widget_spacing = 6;
          font_scale = 1.0;
          background_opacity = 0.93;
          radius = 20;
          border_width = 0.0;
          shadow = false;
          show_tooltip = true;
          auto_hide = false;
          auto_hide_delay_ms = 500;
          show_on_workspace_switch = true;
          thickness = 28;
          scale = 0.9;

          start = [
            "workspaces"
            "tailscale"
            "timer"
            "clock"
            "cpu"
            "temp"
            "ram"
          ];
          center = [ "media" ];
          end = [
            "tray"
            "network"
            "bluetooth"
            "output_volume"
            "input_volume"
            "brightness"
            "battery"
            "notifications"
            "control-center"
          ];
        };

        widget = {
          workspaces = {
            max_label_chars = 2;
            show_labels = false;
            labels_only_when_occupied = true;
            hide_when_empty = false;
            focused_color = "primary";
            occupied_color = "secondary";
            empty_color = "secondary";
          };

          tailscale = {
            type = "davemhammer/tailscale:status";
            show_counts = false;
          };

          timer = {
            type = "noctalia/timer:bar";
            capsule_foreground = "tertiary";
            show_idle_on_horizontal = false;
          };

          clock = {
            format = "{:%H:%M %a, %b %d}";
            vertical_format = "{:%H\n%M\n-\n%d\n%m}";
            tooltip_format = "{:%H:%M %a, %b %d}";
            color = "secondary";
          };

          cpu = {
            type = "sysmon";
            stat = "cpu_usage";
            color = "primary";
          };

          temp = {
            type = "sysmon";
            stat = "cpu_temp";
            color = "primary";
          };

          ram = {
            type = "sysmon";
            stat = "ram_pct";
            color = "primary";
          };

          media = {
            hide_when_no_media = true;
            hide_when_idle = false;
            max_length = 145.0;
            title_scroll = "on_hover";
            hide_album_art = false;
            artist_first = true;
            color = "tertiary";
          };

          tray = {
            hidden = [ ];
            drawer = true;
            hide_passive = true;
            pinned = [
              "Microsoft Teams"
              "You have 1 notification"
              "Slack"
            ];
          };

          network = {
            show_label = false;
            color = "tertiary";
          };

          bluetooth = {
            show_label = false;
            color = "primary";
          };

          output_volume = {
            type = "volume";
            device = "output";
            show_label = true;
            color = "secondary";
            actions.middle = wiremix;
          };

          input_volume = {
            type = "volume";
            device = "input";
            show_label = false;
            icon_color = "tertiary";
            actions.middle = wiremix;
          };

          brightness = {
            show_label = true;
            color = "primary";
          };

          battery = {
            display_mode = "glyph";
            color = "secondary";
          };

          notifications = {
            hide_when_no_unread = false;
            icon_color = "error";
          };

          control-center = {
            glyph = "noctalia";
            icon_color = "tertiary";
          };
        };
      };
    };
}
