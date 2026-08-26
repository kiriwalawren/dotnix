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

      steamos
      gui
      niri
      niri-steamos
      ;
  };
}
