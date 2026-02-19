{
  flake.modules.nixos.installer =
    { lib, pkgs, ... }:
    {
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      nixpkgs = {
        hostPlatform = lib.mkDefault "x86_64-linux";
        config.allowUnfree = true;
      };

      services = {
        openssh = {
          enable = true;
          ports = [ 22 ];
          settings = {
            PermitRootLogin = lib.mkForce "yes";
          };
        };
      };

      boot = {
        kernelPackages = pkgs.linuxPackages_latest;
        supportedFilesystems = lib.mkForce [
          "btrfs"
          "vfat"
        ];
      };
    };
}
