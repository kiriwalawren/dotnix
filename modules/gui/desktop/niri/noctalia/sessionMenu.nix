{
  flake.modules.homeManager.niri = {
    programs.noctalia-shell.settings.sessionMenu = {
      enableCountdown = false;
      countdownDuration = 5000;
      position = "center";
      showHeader = true;
      showKeybinds = true;
      largeButtonsStyle = false;
      largeButtonsLayout = "grid";
      powerOptions = [
        {
          action = "lock";
          command = "";
          countdownEnabled = true;
          enabled = false;
          keybind = "1";
        }
        {
          action = "suspend";
          command = "";
          countdownEnabled = true;
          enabled = true;
          keybind = "2";
        }
        {
          action = "hibernate";
          command = "";
          countdownEnabled = true;
          enabled = true;
          keybind = "3";
        }
        {
          action = "reboot";
          command = "";
          countdownEnabled = true;
          enabled = true;
          keybind = "4";
        }
        {
          action = "logout";
          command = "";
          countdownEnabled = true;
          enabled = true;
          keybind = "5";
        }
        {
          action = "shutdown";
          command = "";
          countdownEnabled = true;
          enabled = true;
          keybind = "6";
        }
        {
          action = "rebootToUefi";
          command = "";
          countdownEnabled = true;
          enabled = true;
          keybind = "7";
        }
      ];
    };
  };
}
