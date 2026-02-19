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
            self'.packages.bootstrap-nixos
            sops
            ssh-to-age
            yq-go
          ];
      };
    };
}
