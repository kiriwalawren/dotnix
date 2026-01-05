{
  name = "home-server";
  modules = [
    ./hardware-configuration.nix

    ../../modules/nixos

    {
      system = {
        disks."/" = {
          devices = ["/dev/vda"];
          encryptDrives = true;
        };
        disks."/data" = {
          devices = ["/dev/vdb" "/dev/vdc"];
          type = "data";
          raidLevel = 1;
          encryptDrives = true;
        };

        encryption.tpm2.enable = true;
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
    }
  ];

  homeOptions.cli.enable = true;
}
