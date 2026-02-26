{
  configurations.nixos.homelab.modules.configuration = {
    imports = [
      ./_hardware-configuration.nix
    ];

    networking.hostName = "homelab";

    system = {
      stateVersion = "25.11";

      disks."/" = {
        devices = [
          "/dev/nvme0n1"
          "/dev/nvme1n1"
        ];
        raidLevel = 0;
      };

      # TODO: remove when ready to switch to headscale
      tailscale.login-server = null;
    };

    # TODO: For now, you need create the headscale server first then register
    # the node with the server
    server.adguardhome.serverIP = "100.99.237.58";

    # Hardware specific media server settings
    nixflix = {
      usenetClients.sabnzbd.settings.misc.cache_limit = "8G";
      jellyfin = {
        encoding = {
          allowHevcEncoding = true;
          enableHardwareEncoding = true;
          hardwareAccelerationType = "vaapi"; # AMD Graphics Card
        };
        system.trickplayOptions.enableHwEncoding = true;
      };
    };
  };
}
