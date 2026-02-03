{
  name = "framework13";
  modules = [
    ./hardware-configuration.nix

    ../../modules/nixos

    {
      user.name = "walawren";
      system = {
        disks."/" = {
          devices = ["/dev/nvme0n1"];
        };

        stateVersion = "25.05"; # Update when reinstalling
        docker.enable = true;
        bootloader.grub.enable = true;
        power-profiles.enable = true;

        tailscale = {
          enable = false;
          # The world is not ready for this yet
          # vpn.enable = true;
        };
      };

      ui = {
        enable = true;
        fingerprint.enable = true;
        virtualisation.enable = true;
      };
    }
  ];
  homeOptions.ui = {
    enable = true;
    nixos.enable = true;
  };
}
