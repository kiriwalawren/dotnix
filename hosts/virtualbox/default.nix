{
  name = "virtualbox";
  modules = [
    ./hardware-configuration.nix

    ({lib, ...}:
      import ../disko-raid.nix {
        inherit lib;
        device = "/dev/vda";
        raidDevice1 = "/dev/vdb";
        raidDevice2 = "/dev/vdc";
      })

    ../../modules/nixos

    {
      system.stateVersion = "25.05"; # Update when reinstalling

      boot.loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot/efi";
        };
        systemd-boot.enable = true;
      };

      # Configure mdadm for RAID
      boot.swraid = {
        enable = true;
        mdadmConf = ''
          MAILADDR root
        '';
      };

      system = {
        cachix-agent.enable = true;
        openssh.enable = true;
        ddns = {
          enable = true;
          domains = ["walawren.com"];
        };
        vpn.enable = true;
        tailscale = {
          enable = true;
          mode = "server";
        };
      };

      user.name = "walawren";
    }
  ];

  homeOptions.cli = {
    btop.enable = true;
    dircolors.enable = true;
    fish.enable = true;
    tmux.enable = true;
  };
}
