{
  flake.wrappers.noctalia.settings = {
    accessibility.ui_scale = 1.0;

    shell = {
      avatar_path = "/home/walawren/.face";
      corner_radius_scale = 1.0;
      screen_corners.enabled = false;
      animation = {
        enabled = false;
        speed = 1.0;
      };
      popup_shadows = false;
      panel.shadow = false;
      password_style = "random";
    };

    lockscreen = {
      lock_before_suspend = true;
      fingerprint = true;
      blur_intensity = 0.0;
      tint_intensity = 0.2;
      monitors = [ ];
    };

    lockscreen_widgets = {
      enabled = false;
    };

    desktop_widgets.enabled = false;

    keybinds = {
      up = [ "Up" ];
      down = [ "Down" ];
      left = [ "Left" ];
      right = [ "Right" ];
      validate = [
        "Return"
        "KP_Enter"
      ];
      cancel = [ "Escape" ];
      delete = [ "Delete" ];
    };
  };
}
