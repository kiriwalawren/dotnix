{
  flake.wrappers.noctalia.settings = {
    shell.panel = {
      control_center_placement = "attached";
      open_near_click_control_center = true;
    };

    control_center = {
      hidden_tabs = [ "monitor" ];
      shortcuts = [
        { type = "wifi"; }
        { type = "bluetooth"; }
        { type = "wallpaper"; }
        { type = "notification"; }
        { type = "power_profile"; }
        { type = "caffeine"; }
        { type = "nightlight"; }
      ];
    };
  };
}
