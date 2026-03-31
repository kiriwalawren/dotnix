{ config, lib, ... }:
let
  keys = config.flake.publicSshKeys;
  user = config.user.name;
in
{
  options.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "walawren";
      description = "The name to use for the user account";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "kiri@walawren.com";
      description = "The user's email";
    };
  };

  config.flake.modules.nixos.base =
    { config, ... }:
    {
      users.mutableUsers = config.wsl.enable;

      users.users.${user} = {
        name = user;
        home = "/home/${user}";
        isNormalUser = true;
        group = "users";

        hashedPasswordFile =
          if !config.wsl.enable then config.sops.secrets."passwords/${user}".path else null;

        openssh.authorizedKeys.keys = keys;

        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
          "input"
          "tty"
        ];
      };
    };

  config.flake.modules.homeManager.base = {
    home = {
      username = user;
      homeDirectory = "/home/${user}";
    };
    programs.home-manager.enable = true;
  };
}
