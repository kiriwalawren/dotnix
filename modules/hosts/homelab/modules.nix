{ config, ... }:
{
  configurations.nixos.homelab.modules = {
    inherit (config.flake.modules.nixos)
      adguardhome
      auto-deploy
      backup
      base
      homelab
      ssh
      tailscale-server-mode
      vpn

      # Uncomment for temporary gaming
      # bluetooth
      # gaming
      # gui
      # niri
      # sound
      ;
  };
}
