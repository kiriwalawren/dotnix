{
  flake.modules.nixos.iso =
    { modulesPath, ... }:
    {
      imports = [
        "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
        "${modulesPath}/installer/cd-dvd/channel.nix"
      ];

      # The default compression-level is (6) and takes too long on some machines (>30m). 3 takes <2m
      isoImage.squashfsCompression = "zstd -Xcompression-level 3";
    };
}
