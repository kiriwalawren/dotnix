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
      widget_order = [ "lockscreen-login-box@eDP-1" ];
      widget."lockscreen-login-box@eDP-1" = {
        type = "login_box";
        output = "eDP-1";
        cx = 720.0;
        cy = 778.0;
        settings = {
          background_color = "surface_variant";
          background_opacity = 0.88;
          background_radius = 12.0;
          center_password_text = false;
          input_opacity = 1.0;
          input_radius = 6.0;
          layout = "regular";
          show_caps_lock = true;
          show_keyboard_layout = true;
          show_login_button = true;
          show_media = true;
          show_password_reveal = true;
          show_session_buttons = true;
          show_unlock_hint = true;
          show_weather = true;
        };
      };
    };

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
