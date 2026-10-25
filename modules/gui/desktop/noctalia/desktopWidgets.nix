{
  flake.wrappers.noctalia.settings.desktop_widgets = {
    enabled = false;
    grid.visible = false;
    widget_order = [
      "media_player"
      "cpu_stat"
    ];

    widget = {
      media_player = {
        type = "media_player";
        output = "eDP-1";
        cx = 20.0;
        cy = 860.0;
        settings = {
          hide_when_no_media = true;
          background = true;
          audio_visualizer = true;
        };
      };

      cpu_stat = {
        type = "sysmon";
        output = "eDP-1";
        cx = 20.0;
        cy = 60.0;
        settings = {
          stat = "cpu_usage";
          background = true;
        };
      };
    };
  };
}
