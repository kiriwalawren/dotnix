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

      # Uncomment for temporary gaming
      # bluetooth
      # gaming
      # gui
      # hyprland
      # sound
      ;
  };
}
