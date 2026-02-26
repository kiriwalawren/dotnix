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
      # tailscale.vpn.enable = true

      # TODO: remove when ready to switch to headscale
      tailscale.login-server = null;
    };
  };
}
