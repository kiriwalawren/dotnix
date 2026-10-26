{ config, ... }: {
  flake.wrappers.noctalia.settings = {
    wallpaper = {
      enabled = true;
      directory = toString config.theme.wallpapers;
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

      default.path = "${toString config.theme.wallpapers}/zombie-boy-smoking-digital-art-4k-wallpaper-uhdpaper.com-6933a.jpg";

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
