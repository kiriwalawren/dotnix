{ inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.hyprland-contrib.overlays.default
  ];
}
