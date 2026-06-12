{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    {
      config,
      self',
      pkgs,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs =
          with pkgs;
          [ config.treefmt.build.wrapper ]
          ++ (lib.attrValues config.treefmt.build.programs)
          ++ [
            age
            cachix
            sops
            self'.packages.bootstrap-nixos
            self'.packages.create-vm
          ];
      };
    };
}
