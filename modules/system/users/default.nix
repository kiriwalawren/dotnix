{
  config,
  lib,
  ...
}:
let
  keys = config.flake.users.sshKeys;
  username = config.user.name;
in
{
  options.user.name = lib.mkOption {
    type = lib.types.str;
    default = "walawren";
    description = "The name to use for the user account";
  };

  config.flake.modules.nixos.base =
    { config, ... }:
    {
      users.mutableUsers = config.wsl.enable;

      users.users.${username} = {
        name = username;
        home = "/home/${username}";
        isNormalUser = true;
        group = "users";

        hashedPasswordFile =
          if !config.wsl.enable then config.sops.secrets."passwords/${username}".path else null;

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
      inherit username;
      homeDirectory = "/home/${username}";
    };
    programs.home-manager.enable = true;
  };
}
