{ config, ... }:
let
  nixosModules = config.flake.modules.nixos;
in
{
  flake.modules.nixos.pocket-id =
    { config, ... }:
    {
      imports = [ nixosModules.ddns ];
    };
}
