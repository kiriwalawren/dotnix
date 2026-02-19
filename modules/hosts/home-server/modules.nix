{ config, ... }:
{
  configurations.nixos.home-server.modules = {
    inherit (config.flake.modules.nixos)
      auto-deploy
      base
      bluetooth
      homelab
      nixflix
      sound
      tailscale-server
      ;
  };
}
