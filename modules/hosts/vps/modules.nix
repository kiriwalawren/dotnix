{ config, ... }:
{
  configurations.nixos.vps.modules = {
    inherit (config.flake.modules.nixos)
      adguardhome # offsite backup incase homelab goes down
      deploy
      backup
      base
      # expose-ssh
      ssh
      tailscale-server-mode
      vps
      ;
  };
}
