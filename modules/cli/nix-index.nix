{ inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = [ inputs.nix-index-database.nixosModules.default ];

    programs.nix-index-database.comma.enable = true;
  };
}
