{ config, ... }:
{
  configurations.nixos.vps.modules = {
    inherit (config.flake.modules.nixos)
      adguardhome # offsite backup incase homelab goes down
      auto-deploy
      backup
      base
      expose-ssh
      ssh
      tailscale-server-mode
      vpn
      vps
      ;
  };
}
