{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { config, pkgs, ... }:
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
            ssh-to-age
            yq-go
          ];
      };
    };
}
