{ config, ... }: {
  flake.wrappers.noctalia.settings = {
    wallpaper = {
      enabled = true;
      directory = "${config.theme.wallpapers}";
      per_monitor_directories = false;
      fill_mode = "crop";
      fill_color = "#000000";
      transition = [
        "fade"
        "disc"
        "stripes"
        "wipe"
        "honeycomb"
      ];
      transition_duration = 1500.0;
      transition_on_startup = true;
      edge_smoothness = 0.05;

      default.path = "${config.theme.defaultWallpaper}";

      automation = {
        enabled = true;
        order = "random";
        interval_seconds = 3600;
      };
    };

    shell.panel = {
      wallpaper_placement = "attached";
      wallpaper_show_names = true;
    };
  };
}
