{
  flake.wrappers.noctalia.settings.shell = {
    panel = {
      session_placement = "floating";
      session_position = "center";
    };

    session = {
      grid = false;
      show_shortcuts = true;
      actions = [
        {
          action = "lock";
          enabled = false;
          shortcut = "1";
          countdown_seconds = 0.0;
        }
        {
          action = "suspend";
          enabled = true;
          shortcut = "2";
          countdown_seconds = 0.0;
        }
        {
          action = "command";
          command = "systemctl hibernate";
          label = "Hibernate";
          glyph = "zzz";
          enabled = true;
          shortcut = "3";
          countdown_seconds = 0.0;
        }
        {
          action = "reboot";
          enabled = true;
          shortcut = "4";
          countdown_seconds = 0.0;
        }
        {
          action = "logout";
          enabled = true;
          shortcut = "5";
          countdown_seconds = 0.0;
        }
        {
          action = "shutdown";
          enabled = true;
          shortcut = "6";
          countdown_seconds = 0.0;
          variant = "destructive";
        }
        {
          action = "command";
          command = "systemctl reboot --firmware-setup";
          label = "Reboot to UEFI";
          glyph = "cpu";
          enabled = true;
          shortcut = "7";
          countdown_seconds = 0.0;
        }
      ];
    };
  };
}
