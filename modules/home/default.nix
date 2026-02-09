{
  hostConfig,
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

  home = {
    inherit (hostConfig.system) stateVersion;
    username = hostConfig.user.name;
    homeDirectory = hostConfig.users.users.${hostConfig.user.name}.home;
  };

  catppuccin.flavor = theme.variant;
}
