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

      ddns.enable = true;
    };

    server.adguardhome = {
      serverIP = "100.64.0.6";
      subdomain = "dns2";
    };

    # Hardware & host specific media server settings
    nixflix = {
      usenetClients.sabnzbd.settings.misc.cache_limit = "8G";
      jellyfin = {
        encoding = {
          allowHevcEncoding = true;
          enableHardwareEncoding = true;
          hardwareAccelerationType = "vaapi"; # AMD Graphics Card
          enableTonemapping = true;
        };
        system.trickplayOptions.enableHwEncoding = true;
      };
    };
  };
}
