{
  flake.modules.homeManager.niri.programs.noctalia-shell.settings = {
    plugins = {
      autoUpdate = true;
      sources = [
        {
          enabled = true;
          name = "Official Source";
          url = "https://github.com/noctalia-dev/noctalia-plugins";
        }
      ];
      states = {
        tailscale = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        timer = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
      };
      version = 1;
    };

    pluginSettings = {
      tailscale = {
        refreshInterval = 5000;
        compactMode = true;
        showIpAddress = false;
        showPeerCount = false;
        hideDisconnected = false;
        terminalCommand = "kitty";
        pingCount = 5;
        defaultPeerAction = "copy";
      };

      timer = {
        defaulltDuration = 0;
        compactMode = true;
        iconColor = "tertiary";
        textColor = "tertiary";
      };
    };
  };
}
