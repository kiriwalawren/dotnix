{
  name = "home-server";
  modules = [
    ./hardware-configuration.nix

    ({lib, ...}:
      import ../disko-raid.nix {
        inherit lib;
        device = "/dev/vda";
        raidDevice1 = "/dev/vdb";
        raidDevice2 = "/dev/vdc";
        encryptDrives = true;
      })

    ../../modules/nixos

    {
      system.stateVersion = "25.05"; # Update when reinstalling
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

      system = {
        encryption.tpm2.enable = true;
        cachix-agent.enable = true;
        openssh.enable = true;
        tailscale = {
          enable = true;
          mode = "server";
        };
      };

      server.enable = true;
    }
  ];

  homeOptions.cli.enable = true;
}
