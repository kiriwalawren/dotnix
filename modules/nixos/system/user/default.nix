{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  pubKeys = filesystem.listFilesRecursive ./keys;
in {
  meta.doc = lib.mdDoc ''
    User account configuration for NixOS systems.

    Configures a user account with dynamic username support, SSH key management,
    and Fish shell integration. Supports both minimal and full installations
    with appropriate password handling for each scenario.
  '';

  options = {
    user.name = mkOption {
      type = types.str;
      default = "walawren";
      example = "kiri";
      description = lib.mdDoc ''
        The name to use for the user account. Each unique value needs a
        corresponding SSH key in the `private_keys` object of `secrets.yaml`.
      '';
    };

    isMinimal = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = lib.mdDoc ''
        Whether this is a minimal host installation. Affects password handling
        and available features.
      '';
    };
  };

  config = {
    users.mutableUsers = config.wsl.enable;

    users.users.${config.user.name} = {
      inherit (config.user) name;
      home = "/home/${config.user.name}";
      isNormalUser = true;
      group = "users";

      hashedPasswordFile =
        if !config.isMinimal && !config.wsl.enable
        then config.sops.secrets."passwords/${config.user.name}".path
        else null;
      hashedPassword =
        if config.isMinimal && !config.wsl.enable
        then "$y$j9T$M93AAG05U9RRsjhXIamCL/$YT5Eu.P4ci1hx11vb0P/loGWp6Qpz7hcENtUAj2jryC"
        else null;

      openssh.authorizedKeys.keys = lists.forEach pubKeys (key: builtins.readFile key);

      extraGroups = ["wheel" "networkmanager" "audio" "sound" "video" "input" "tty"];
    };

    # Set fish as default in bash
    programs.bash.interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
    programs.fish.enable = true;
  };
}
