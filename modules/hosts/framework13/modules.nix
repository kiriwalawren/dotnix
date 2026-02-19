{ config, ... }:
{
  configurations.nixos.framework13.modules = {
    inherit (config.flake.modules.nixos)
      base
      bluetooth
      docker
      fingerprint
      gui
      laptop
      sound
      virtualisation
      ;
  };
}
