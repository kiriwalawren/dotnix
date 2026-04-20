{ config, ... }:
let
  user = config.user.name;
in
{
  nixpkgs.config.allowUnfreePackages = [
    "broadcom-bt-firmware"
    "b43-firmware"
    "xone-dongle-firmware"
    "facetimehd-calibration"
    "facetimehd-firmware"
  ];

  configurations.nixos.framework13.modules.configuration =
    { config, ... }:
    {
      imports = [
        ./_hardware-configuration.nix
      ];

      networking.hostName = "framework13";
      nixpkgs.hostPlatform = "x86_64-linux";

      system = {
        stateVersion = "25.05";

        backup.paths = [ "${config.users.users.${user}.home}/photos-staging" ];

        disks."/" = {
          devices = [ "/dev/nvme0n1" ];
        };

        tailscale.exitNode.enable = true;
      };
    };
}
