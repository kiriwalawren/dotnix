{ config, lib, ... }:
{
  configurations.nixos.wsl.module = {
    imports = with config.flake.modules.nixos; [
      base
      wsl
      docker
    ];

    networking.hostName = "wsl";
    system.stateVersion = "23.11";
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
