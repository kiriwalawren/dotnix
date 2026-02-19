{
  lib,
  config,
  inputs,
  ...
}:
{
  options.nixpkgs = {
    config = {
      allowUnfreePredicate = lib.mkOption {
        type = lib.types.functionTo lib.types.bool;
        default = _: false;
      };
      allowUnfreePackages = lib.mkOption {
        type = lib.types.listOf lib.types.singleLineStr;
        default = [ ];
      };
    };
    overlays = lib.mkOption {
      type = lib.types.listOf lib.types.unspecified;
      default = [ ];
    };
  };

  config = {
    perSystem =
      { system, ... }:
      {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          inherit (config.nixpkgs) config overlays;
        };
      };

    flake.modules.nixos.base.nixpkgs = {
      config = {
        allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) config.nixpkgs.config.allowUnfreePackages
          || config.nixpkgs.config.allowUnfreePredicate pkg;
      };
      inherit (config.nixpkgs) overlays;
    };
  };
}
