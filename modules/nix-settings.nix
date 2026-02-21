{
  lib,
  config,
  inputs,
  ...
}:
{
  options.nix.settings = {
    keep-outputs = lib.mkOption { type = lib.types.bool; };
    experimental-features = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      default = [ ];
    };
    extra-system-features = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      default = [ ];
    };
  };
  config = {
    nix.settings = {
      keep-outputs = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

    flake.modules.nixos.base = {
      imports = [ inputs.determinate.nixosModules.default ];

      nix = {
        inherit (config.nix) settings;
        optimise.automatic = true;
      };

      environment.etc."nix/nix.custom.conf".text = ''
        eval-cores = 0
      '';
    };

    flake.modules.homeManager.base.nix = {
      inherit (config.nix) settings;
    };
  };
}
