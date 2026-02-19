{
  lib,
  config,
  self,
  ...
}:
let
  # Calculate git revision for build tracking
  gitRev = self.rev or self.dirtyRev or "unknown";

  # Create short revision for display
  shortRev = lib.strings.substring 0 7 gitRev;
in
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
      _name:
      { module }:
      lib.nixosSystem {
        modules = [
          module
          (
            { config, ... }:
            {
              system = {
                # Set build label to include git revision
                nixos.label = lib.mkForce "${config.system.nixos.version}-${shortRev}";
                configurationRevision = gitRev;
              };
            }
          )
        ];
      }
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
