{
  nixpkgs,
  self,
  overlays,
  ...
}: let
  inherit (self) inputs;

  # Calculate git revision for build tracking
  gitRev = self.rev or self.dirtyRev or "unknown";

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
          inputs.nixflix.nixosModules.default
        ]
        ++ modules;
      specialArgs = {
        inherit inputs system name homeOptions gitRev;
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
    (import ./framework13)
    (import ./home-server)
    (import ./installer)
  ]
