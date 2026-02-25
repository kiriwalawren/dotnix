{ config, ... }:
{
  configurations.nixos.wsl.modules = {
    inherit (config.flake.modules.nixos)
      base
      cli
      wsl
      docker
      ;
  };
}
