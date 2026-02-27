{
  nixpkgs.config.allowUnfreePackages = [
    "broadcom-bt-firmware"
    "b43-firmware"
    "xone-dongle-firmware"
    "facetimehd-calibration"
    "facetimehd-firmware"
  ];

  configurations.nixos.framework13.modules.configuration = {
    imports = [
      ./_hardware-configuration.nix
    ];

    networking.hostName = "framework13";
    nixpkgs.hostPlatform = "x86_64-linux";

    system = {
      stateVersion = "25.05";

      disks."/" = {
        devices = [ "/dev/nvme0n1" ];
      };

      # The world is not ready for this yet
      # enable when NYC upload speeds are faster
      # tailscale.vpn.enable = true
    };
  };
}
