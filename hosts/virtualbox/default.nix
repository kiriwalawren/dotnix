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
        vpn = {
          enable = true;
          killSwitch.enable = true;
        };
        tailscale = {
          enable = true;
          mode = "server";
        };
      };

      server.enable = true;
    }

    ({
      config,
      pkgs,
      lib,
      ...
    }: {
      # RAID encryption auto-unlock
      sops.secrets.raid-encryption-key = {
        mode = "0400";
      };

      # Prevent auto-detection of LUKS device in initrd
      boot.initrd.luks.devices = lib.mkForce {};

      # Unlock RAID after boot using systemd
      systemd.services.unlock-raid = {
        description = "Unlock and mount encrypted RAID array";
        wantedBy = ["multi-user.target"];
        after = ["mdmonitor.service"];
        requires = ["mdmonitor.service"];
        unitConfig = {
          ConditionPathExists = [
            config.sops.secrets.raid-encryption-key.path
            "!/dev/mapper/cryptraid"
          ];
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          # Wait for RAID device to be ready
          ${pkgs.coreutils}/bin/timeout 30 ${pkgs.bash}/bin/sh -c 'while [ ! -e /dev/md/raid1p1 ]; do ${pkgs.coreutils}/bin/sleep 1; done'

          # Unlock the LUKS device
          ${pkgs.cryptsetup}/bin/cryptsetup luksOpen /dev/md/raid1p1 cryptraid --key-file ${config.sops.secrets.raid-encryption-key.path}

          # Wait for the device mapper device to be ready
          ${pkgs.coreutils}/bin/timeout 30 ${pkgs.bash}/bin/sh -c 'while [ ! -e /dev/mapper/cryptraid ]; do ${pkgs.coreutils}/bin/sleep 1; done'

          # Give the kernel a moment to recognize the filesystem
          ${pkgs.coreutils}/bin/sleep 1

          # Mount the filesystem
          ${pkgs.util-linux}/bin/mount /dev/mapper/cryptraid /data
        '';
        preStop = ''
          ${pkgs.util-linux}/bin/umount /data || true
        '';
        postStop = ''
          ${pkgs.cryptsetup}/bin/cryptsetup luksClose cryptraid || true
        '';
      };

      # Define mount point (but don't auto-mount - let the service handle it)
      fileSystems."/data" = {
        device = "/dev/mapper/cryptraid";
        fsType = "ext4";
        options = ["noauto" "nofail"];
      };
    })
  ];

  homeOptions.cli = {
    btop.enable = true;
    dircolors.enable = true;
    fish.enable = true;
    tmux.enable = true;
  };
}
