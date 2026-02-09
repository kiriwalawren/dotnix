{
  name = "installer";
  modules = [
    (
      {
        lib,
        modulesPath,
        pkgs,
        ...
      }:
      with lib;
      let
        pubKeys = filesystem.listFilesRecursive ../../modules/nixos/system/user/keys;
      in
      {
        imports = [
          "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
          "${modulesPath}/installer/cd-dvd/channel.nix"
        ];

        users.users = {
          root = {
            initialHashedPassword = mkForce "$y$j9T$M93AAG05U9RRsjhXIamCL/$YT5Eu.P4ci1hx11vb0P/loGWp6Qpz7hcENtUAj2jryC";
            openssh.authorizedKeys.keys = lists.forEach pubKeys (key: builtins.readFile key);
          };
          nixos = {
            initialHashedPassword = mkForce "$y$j9T$M93AAG05U9RRsjhXIamCL/$YT5Eu.P4ci1hx11vb0P/loGWp6Qpz7hcENtUAj2jryC";
            openssh.authorizedKeys.keys = lists.forEach pubKeys (key: builtins.readFile key);
          };
        };

        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];

        # The default compression-level is (6) and takes too long on some machines (>30m). 3 takes <2m
        isoImage.squashfsCompression = "zstd -Xcompression-level 3";

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
      }
    )
  ];
}
