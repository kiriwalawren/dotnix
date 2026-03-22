{ config, ... }:
{
  configurations.nixos.vps.modules = {
    inherit (config.flake.modules.nixos)
      auto-deploy
      base
      ddns
      headscale
      pocket-id
      adguardhome # offsite backup incase homelab goes down
      ssh
      expose-ssh
      tailscale-server-mode
      ;
  };
}
