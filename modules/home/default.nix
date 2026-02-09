{
  inputs,
  theme,
  ...
}:
{
  imports = [
    ./cli
    ./sops.nix
    ./ui

    inputs.catppuccin.homeModules.catppuccin
  ];

  catppuccin = {
    enable = true;
    inherit (theme) accent;
    flavor = theme.variant;
  };
}
