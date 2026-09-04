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
          ++ builtins.attrValues self'.packages
          ++ [
            age
            cachix
            deploy-rs
            sops
          ];
      };
    };
}
