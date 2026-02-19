{ config, ... }:
{
  configurations.nixos.installer.modules.configuration = {
    imports = with config.flake.modules.nixos; [
      iso
      installer
    ];

    networking.hostName = "installer";
  };
}
