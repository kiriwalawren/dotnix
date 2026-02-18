{ inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = [ inputs.nixos-wsl.nixosModules.wsl ];
  };

  flake.modules.nixos.wsl = {
    wsl.enable = true;
  };
}
