{ config, ... }:
{
  configurations.nixos.homelab.modules = {
    inherit (config.flake.modules.nixos)
      auto-deploy
      base
      adguardhome
      nixflix
      ssh
      tailscale-server-mode
      ssh-microvm

      # Uncomment for temporary gaming
      # bluetooth
      # gaming
      # gui
      # sound
      ;
  };
}
