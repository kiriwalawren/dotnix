{
  flake.modules.homeManager.niri.programs.noctalia-shell.settings.desktopWidgets = {
    enabled = true;
    overviewEnabled = true;
    gridSnap = false;
    monitorWidgets = [
      {
        name = "eDP-1";
        widgets = [
          {
            hideMode = "idle";
            id = "MediaPlayer";
            roundedCorners = true;
            showAlbumArt = true;
            showBackground = true;
            showButtons = true;
            showVisualizer = true;
            visualizerType = "wave";
            x = 20;
            y = 860;
          }
          {
            diskPath = "/";
            id = "SystemStat";
            layout = "bottom";
            roundedCorners = true;
            scale = 1;
            showBackground = true;
            statType = "CPU";
            x = 20;
            y = 60;
          }
        ];
      }
    ];
  };
}
