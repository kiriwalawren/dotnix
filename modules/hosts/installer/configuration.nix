{ config, ... }:
{
  configurations.nixos.installer.module = {
    imports = with config.flake.modules.nixos; [
      iso
      installer
    ];

    networking.hostName = "installer";
  };
}
