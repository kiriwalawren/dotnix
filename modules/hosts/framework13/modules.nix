{ config, ... }:
{
  configurations.nixos.framework13.modules = {
    inherit (config.flake.modules.nixos)
      base
      cli
      bluetooth
      docker
      fingerprint
      gui
      laptop
      sound
      virtualisation
      # ziti-edge-tunnel # disables tailscale
      ;
  };
}
