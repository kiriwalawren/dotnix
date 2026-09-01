{ config, ... }:
{
  configurations.nixos.framework13.modules = {
    inherit (config.flake.modules.nixos)
      backup
      base
      bluetooth
      docker
      fingerprint
      gui
      laptop
      niri
      sound
      virtualisation
      # ziti-edge-tunnel # disables tailscale
      ;
  };
}
