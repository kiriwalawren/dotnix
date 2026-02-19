{ config, inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = [
      inputs.home-manager.nixosModules.home-manager
    ];

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
              home.stateVersion = osConfig.system.stateVersion;
            }
          )
          config.flake.modules.homeManager.base
        ];
      };
    };
  };

  flake.modules.nixos.gui = {
    home-manager.users.${config.flake.meta.owner.username}.imports = [
      config.flake.modules.homeManager.gui
    ];
  };

  flake.modules.homeManger.base = {
    home = {
      username = config.user.name;
      homeDirectory = "/home/${config.user.name}";
    };
    programs.home-manager.enable = true;
  };
}
