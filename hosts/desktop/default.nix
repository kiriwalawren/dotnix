{
  name = "desktop";
  modules = [
    ./hardware-configuration.nix

    ../../modules/nixos

    {
      user.name = "kiri";
      system = {
        disks."/" = {
          devices = ["/dev/nvme1n1"];
        };

        stateVersion = "25.05"; # Update when reinstalling
        docker.enable = true;
        bootloader.grub.enable = true;
        openssh.enable = true;
        power-profiles.enable = true;
        tailscale.enable = true;
      };

      ui = {
        enable = true;
        gaming.enable = true;
      };
    }
  ];
  homeOptions.ui = {
    enable = true;
    nixos.enable = true;
  };
}
