{ inputs, ... }:
{
  flake.modules.nixos.use-in-pkgs.nixpkgs.overlays = [
    (final: prev: inputs.self.packages.${prev.system} or { })
  ];
}
