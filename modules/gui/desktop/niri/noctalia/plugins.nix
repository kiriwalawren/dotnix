{
  flake.wrappers.noctalia-shell.settings = {
    plugins = {
      autoUpdate = true;
      notifyUpdates = true;
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
        compactMode = false;
        showIpAddress = true;
        showPeerCount = true;
        hideDisconnected = false;
        hideMullvadExitNodes = true;
        loginServer = "";
        showSearchBar = false;
        sshUsername = "";
        taildropDownloadDir = "~/Downloads";
        taildropEnabled = true;
        taildropReceiveMode = "operator";
        terminalCommand = "";
        pingCount = 5;
        defaultPeerAction = "copy-ip";
      };

      timer = {
        defaultDuration = 0;
        compactMode = false;
        iconColor = "tertiary";
        textColor = "tertiary";
      };
    };
  };
}
