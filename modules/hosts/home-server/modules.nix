{ config, ... }:
{
  configurations.nixos.home-server.modules = {
    inherit (config.flake.modules.nixos)
      base
      tailscale-server
      auto-deploy
      homelab
      nixflix
      ;
  };
}
