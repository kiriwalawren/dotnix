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
    };

    server.adguardhome.serverIP = "100.64.0.6";

    # Hardware & host specific media server settings
    nixflix = {
      dns = [ "127.0.0.1" ]; # Because AdGuard Home is installed locally

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
