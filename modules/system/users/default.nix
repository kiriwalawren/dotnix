{ config, ... }:
let
  keys = config.flake.publicSshKeys;
in
{

  flake.modules.nixos.base =
    { config, lib, ... }:
    {
      options.user = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "walawren";
          description = "The name to use for the user account";
        };

        displayName = lib.mkOption {
          type = lib.types.str;
          default = "Kiri Carlson";
          description = "The display name to use for the user.";
        };

        email = lib.mkOption {
          type = lib.types.str;
          default = "kiri@walawren.com";
          description = "The user's email";
        };
      };

      config = {
        users.mutableUsers = config.wsl.enable;

        users.users.${config.user.name} = {
          name = config.user.name;
          home = "/home/${config.user.name}";
          isNormalUser = true;
          group = "users";

          hashedPasswordFile =
            if !config.wsl.enable then config.sops.secrets."passwords/${config.user.name}".path else null;

          openssh.authorizedKeys.keys = keys;

          extraGroups = [
            "wheel"
            "networkmanager"
            "video"
            "input"
            "tty"
            "media"
          ];
        };
      };
    };

  flake.modules.homeManager.base = { lib, ... }: {
    options.home = {
      email = lib.mkOption {
        type = lib.types.str;
        default = "kiri@walawren.com";
        description = "The user's email";
      };

      displayName = lib.mkOption {
        type = lib.types.str;
        default = "Kiri Carlson";
        description = "The display name to use for the user.";
      };
    };
  };
}
