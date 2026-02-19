{ config, ... }:
{
  configurations.nixos.home-server.modules = {
    inherit (config.flake.modules.nixos)
      auto-deploy
      base
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
