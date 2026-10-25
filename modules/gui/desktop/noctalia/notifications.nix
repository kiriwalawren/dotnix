{
  flake.wrappers.noctalia.settings = {
    notification = {
      enable_daemon = true;
      monitors = [ ];
      position = "bottom_right";
      layer = "overlay";
      background_opacity = 0.85;
      keep_dismissed_in_history = false;
    };

    audio.enable_notification_sounds = false;

    osd.kinds.keyboard_layout = true;
  };
}
