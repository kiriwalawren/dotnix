{ config, ... }:
{
  configurations.nixos.homelab.modules = {
    inherit (config.flake.modules.nixos)
      auto-deploy
      base
      dns-blackhole
      homelab
      nixflix
      ssh
      tailscale-server

      # Uncomment for temporary gaming
      # bluetooth
      # gaming
      # gui
      # sound
      ;
  };
}
