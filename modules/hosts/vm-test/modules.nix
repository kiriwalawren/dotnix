{ config, ... }:
{
  configurations.nixos.vm-test.modules = {
    inherit (config.flake.modules.nixos)
      base
      homelab
      ssh
      encryption
      tailscale-server-mode

      # Uncomment for temporary gaming
      # bluetooth
      # gaming
      # gui
      # hyprland
      # sound
      ;
  };
}
