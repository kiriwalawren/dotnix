{
  config,
  inputs,
  theme,
  homeOptions ? {},
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${config.user.name} =
      {
        imports = [
          ../home
        ]; # Home Options
      }
      // homeOptions;

    # Optionally, use home-manager.extraSpecialArgs to pass
    # arguments to home.nix
    extraSpecialArgs = {
      inherit inputs theme;
      hostConfig = config;
    };
  };
}
