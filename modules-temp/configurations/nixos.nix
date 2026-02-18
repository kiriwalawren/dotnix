{ lib, config, ... }:
{
  options.configurations.nixos = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options.module = lib.mkOption {
          type = lib.types.deferredModule;
        };
      }
    );
  };

  config.flake = {
    nixosConfigurations = lib.flip lib.mapAttrs config.configurations.nixos (
      _name: { module }: lib.nixosSystem { modules = [ module ]; }
    );

    checks = lib.mkMerge (
      lib.mapAttrsToList (name: nixos: {
        ${nixos.config.nixpkgs.hostPlatform.system} = {
          "configurations/nixos/${name}" = nixos.config.system.build.toplevel;
        };
      }) config.flake.nixosConfigurations
    );
  };
}
