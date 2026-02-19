{ config, ... }:
let
  user = config.user.name;
in
{
  flake.modules.nixos.base = {
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
        ];
      };
    };
  };

  flake.modules.homeManger.base = {
    home = {
      username = user;
      homeDirectory = "/home/${user}";
    };
    programs.home-manager.enable = true;
  };
}
