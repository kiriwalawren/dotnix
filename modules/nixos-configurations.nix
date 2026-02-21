{
  config,
  inputs,
  lib,
  self,
  ...
}:
let
  user = config.user.name;

  # Calculate git revision for build tracking
  gitRev = self.rev or self.dirtyRev or "unknown";
  # Create short revision for display
  shortRev = lib.strings.substring 0 7 gitRev;
in
{
  options.configurations.nixos = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options.modules = lib.mkOption {
          type = lib.types.attrsOf lib.types.deferredModule;
          default = { };
        };
      }
    );
  };

  config.flake = {
    nixosConfigurations = lib.flip lib.mapAttrs config.configurations.nixos (
      _name:
      { modules, ... }:
      let
        matchingHmModules = lib.filterAttrs (name: _: modules ? ${name}) config.flake.modules.homeManager;
        hasHmModules = matchingHmModules != { };
      in
      lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules =
          (lib.attrValues modules)
          ++ lib.optionals hasHmModules [
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.users.${user}.imports = lib.attrValues matchingHmModules;
            }
          ]
          ++ [
            inputs.determinate.nixosModules.default
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
