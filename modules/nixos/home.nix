{
  config,
  pkgs,
  homeOptions ? { },
  inputs,
  lib,
  theme,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${config.user.name} = {
      imports = [
        ../home
        {
          home = {
            inherit (config.system) stateVersion;
            username = config.user.name;
            homeDirectory = config.users.users.${config.user.name}.home;
          };

          cli.enable = lib.mkIf config.wsl.enable (lib.mkDefault true);
          ui.nixos.hyprland.hyprlock.fingerprint.enable = config.ui.fingerprint.enable;
        }

        {
          config = lib.mkIf config.wsl.enable {
            home = {
              packages = with pkgs; [
                wslu
                wsl-open
                (pkgs.writeShellScriptBin "xdg-open" "exec -a $0 ${wsl-open}/bin/wsl-open $@")
              ];

              sessionVariables = {
                BROWSER = "wsl-open";
              };
            };
          };
        }
      ]; # Home Options
    }
    // homeOptions;

    # Optionally, use home-manager.extraSpecialArgs to pass
    # arguments to home.nix
    extraSpecialArgs = {
      inherit inputs theme;
    };
  };
}
