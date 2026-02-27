{
  flake.modules.nixos.virtualisation = {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
}
