{ config, ... }:
{
  configurations.nixos.framework13.modules = {
    inherit (config.flake.modules.nixos)
      base
      laptop
      fingerprint
      virtualisation
      docker
      ;
  };
}
