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
      steamos
      tailscale-server-mode

      # TODO: figure out desktop mode for steam os
      # gui
      # niri
      # niri-homelab
      ;
  };
}
