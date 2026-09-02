{
  flake.modules.nixos.base = { config, ... }: {
    programs.dconf.enable = true; # Configuration System & Setting Management - required for Home Manager

    home-manager = {
      backupFileExtension = "backup";
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${config.user.name} = {
        imports = [
          (
            { osConfig, ... }:
            {
              home = {
                username = config.user.name;
                email = config.user.email;
                displayName = config.user.displayName;
                homeDirectory = "/home/${config.user.name}";
                stateVersion = osConfig.system.stateVersion;
                enableNixpkgsReleaseCheck = false;
              };
            }
          )
        ];
      };
    };
  };

  flake.modules.homeManager.base = {
    programs.home-manager.enable = true;
  };
}
