{
  name = "framework13";
  modules = [
    ./hardware-configuration.nix

    ({lib, ...}:
      import ../disko.nix {
        inherit lib;
        device = "/dev/nvme0n1";
      })

    ../../modules/nixos

    {
      user.name = "walawren";
      system = {
        stateVersion = "25.05"; # Update when reinstalling
        docker.enable = true;
        bootloader.grub.enable = true;
        power-profiles.enable = true;
        tailscale.enable = true;
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
