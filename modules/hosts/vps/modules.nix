{ config, ... }:
{
  configurations.nixos.vps.modules = {
    inherit (config.flake.modules.nixos)
      base
      ddns
      headscale
      auth
      adguardhome # offsite backup incase homelab goes down
      ssh
      expose-ssh
      tailscale-server-mode
      ;
  };
}
