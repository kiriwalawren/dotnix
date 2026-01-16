{
  name = "home-server";
  modules = [
    ./hardware-configuration.nix

    ../../modules/nixos

    {
      system = {
        disks."/" = {
          devices = ["/dev/nvme0n1" "/dev/nvme1n1"];
          raidLevel = 0;
        };

        bootloader.grub.enable = true;
        cachix-agent.enable = true;
        openssh.enable = true;
        tailscale = {
          enable = true;
          mode = "server";
        };

        stateVersion = "25.11"; # Update when reinstalling
      };

      user.name = "walawren";

      boot = {
        # Configure mdadm for RAID
        swraid = {
          enable = true;
          mdadmConf = ''
            MAILADDR root
          '';
        };
      };

      server.enable = true;
      nixflix = {
        sabnzbd.settings.misc.cache_limit = "8G";
        jellyfin.encoding = {
          allowHevcEncoding = true;
          enableHardwareEncoding = true;
          hardwareAccelerationType = "vaapi"; # AMD Graphics Card
        };
      };

      # Uncomment for temporary gaming
      # ui = {
      #   enable = true;
      #   gaming.enable = true;
      # };
    }
  ];

  homeOptions = {
    cli.enable = true;

    # Uncomment for temporary gaming
    # ui = {
    #   enable = true;
    #   nixos.enable = true;
    # };
  };
}
