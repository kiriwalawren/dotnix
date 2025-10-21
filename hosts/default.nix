{
  nixpkgs,
  self,
  overlays,
  ...
}: let
  inherit (self) inputs;

  mkNixosConfiguration = {
    name,
    system ? "x86_64-linux",
    modules,
    homeOptions ? {},
  }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      modules =
        [
          {
            nixpkgs = {
              inherit overlays;
              config.allowUnfree = true;
            };
          }
          inputs.disko.nixosModules.disko
        ]
        ++ modules;
      specialArgs = {
        inherit inputs system name homeOptions;
        theme = import ../theme;
      };
    };

  mkNixosConfigurations = nixpkgs.lib.foldl (
    acc: conf:
      {
        "${conf.name}" = mkNixosConfiguration conf;
      }
      // acc
  ) {};
in
  mkNixosConfigurations [
    (import ./wsl)
    (import ./desktop)
    (import ./framework13)
    (import ./virtualbox)
    (import ./installer)
  ]
