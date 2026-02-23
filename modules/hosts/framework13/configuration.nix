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
    };

    # sops.secrets."ziti-identities/framework13/freewave-dev-staging" = { };
    # programs.ziti-edge-tunnel.enrollment.identities = [
    #
    # ];
  };
}
