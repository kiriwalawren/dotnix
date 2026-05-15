{ inputs, ... }:
{
  flake.modules.nixos.use-in-pkgs.nixpkgs.overlays = [
    (_final: prev: inputs.self.packages.${prev.system} or { })
  ];
}
