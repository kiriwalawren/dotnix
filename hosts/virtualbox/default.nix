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
        encryptedDataDrive = true;
      })

    ../../modules/nixos

    {
      system.stateVersion = "25.05"; # Update when reinstalling
      user.name = "walawren";

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
    }

    ({config, ...}: {
      # RAID encryption auto-unlock
      sops.secrets.raid-encryption-key = {};
      boot.initrd.luks.devices."cryptraid".keyFile = config.sops.secrets.raid-encryption-key.path;
    })
  ];

  homeOptions.cli = {
    btop.enable = true;
    dircolors.enable = true;
    fish.enable = true;
    tmux.enable = true;
  };
}
