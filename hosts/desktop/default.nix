{
  name = "desktop";
  modules = [
    ./hardware-configuration.nix

    ({lib, ...}:
      import ../disko.nix {
        inherit lib;
        device = "/dev/nvme1n1";
      })

    ../../modules/nixos

    {
      system = {
        stateVersion = "25.05"; # Update when reinstalling
        user.name = "kiri";
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
