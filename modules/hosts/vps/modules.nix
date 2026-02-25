{ config, ... }:
{
  configurations.nixos.vps.modules = {
    inherit (config.flake.modules.nixos)
      base
      ddns
      headscale
      auth
      # For now, you need create the headscale server first then register
      # the node with the server
      # dns-blackhole # offsite backup incase homelab goes down
      ssh
      expose-ssh
      ;
  };
}
