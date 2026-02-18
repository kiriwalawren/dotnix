{ inputs, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      cachix-deploy-lib = inputs.cachix-deploy-flake.lib pkgs;
    in
    {
      packages.cachix-deploy-spec = cachix-deploy-lib.spec {
        agents = {
          home-server = self.nixosConfigurations.home-server.config.system.build.toplevel;
        };
      };
    };
}
