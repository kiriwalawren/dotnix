{ config, ... }:
{
  configurations.nixos.home-server.module = {
    imports = with config.flake.modules.nixos; [
      base
      tailscale-server
      auto-deploy
      homelab
      nixflix
      ./_hardware-configuration.nix
    ];

    networking.hostName = "home-sever";

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

    boot = {
      # Configure mdadm for RAID
      swraid = {
        enable = true;
        mdadmConf = ''
          MAILADDR root
        '';
      };
    };

    # Hardware specific media server settings
    nixflix = {
      sabnzbd.settings.misc.cache_limit = "8G";
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
