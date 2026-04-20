{ config, ... }:
{
  configurations.nixos.vm-test.modules = {
    inherit (config.flake.modules.nixos)
      base
      homelab
      ssh
      encryption
      tailscale-server-mode
      ;
  };
}
