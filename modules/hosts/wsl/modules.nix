{ config, ... }:
{
  configurations.nixos.wsl.modules = {
    inherit (config.flake.modules.nixos)
      base
      wsl
      docker
      ;
  };
}
