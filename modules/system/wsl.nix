{ config, inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = [ inputs.nixos-wsl.nixosModules.wsl ];

    wsl = {
      defaultUser = config.user.name;
      interop.includePath = false;
    };
  };

  flake.modules.nixos.wsl = {
    wsl.enable = true;
  };
}
