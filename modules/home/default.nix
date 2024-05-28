{
  inputs,
  theme,
  ...
}: {
  home.stateVersion = "23.11";

  imports = [
    ./cli
    ./desktop

    inputs.catppuccin.homeManagerModules.catppuccin
  ];

  catppuccin.flavor = theme.variant;
}
