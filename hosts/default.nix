{ nixpkgs, self, ... }:
let
  inherit (self) inputs packages;
in
{
  nixos-wsl = nixpkgs.lib.nixosSystem rec {
    system = "x86_64-linux";
    modules = [
      ./nixos-wsl/configuration.nix
      ../modules/user
      ../modules/nixos/home.nix
    ];
    specialArgs = {
      inherit inputs system packages;
      target = "nixos-wsl";
      homeOptions = { modules.cli.enable = true; };
    };
  };

  nixos-desktop = nixpkgs.lib.nixosSystem rec {
    system = "x86_64-linux";
    modules = [
      ./nixos-desktop/configuration.nix
      ../modules/nixos/desktop
      ../modules/user
      ../modules/nixos/home.nix
    ];
    specialArgs = {
      inherit inputs system packages;
      target = "nixos-desktop";
      homeOptions = {
        modules.desktop = {
          enable = true;
          nixos.enable = true;
        };
      };
    };
  };
}
