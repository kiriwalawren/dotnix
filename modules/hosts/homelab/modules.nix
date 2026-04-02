{ config, ... }:
{
  configurations.nixos.homelab.modules = {
    inherit (config.flake.modules.nixos)
      adguardhome
      auto-deploy
      base
      homelab
      ssh
      tailscale-server-mode

      # Uncomment for temporary gaming
      # bluetooth
      # gaming
      # gui
      # niri
      # sound
      ;
  };
}
