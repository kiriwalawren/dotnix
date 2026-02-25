{ inputs, self, ... }:
{
  flake.modules.nixos.auto-deploy =
    { config, ... }:
    {
      sops.secrets.cachix-agent-token = { };

      services.cachix-agent = {
        enable = true;
        credentialsFile = config.sops.secrets.cachix-agent-token.path;
      };
    };

  perSystem =
    { pkgs, ... }:
    let
      cachix-deploy-lib = inputs.cachix-deploy-flake.lib pkgs;
    in
    {
      packages.cachix-deploy-spec = cachix-deploy-lib.spec {
        agents = {
          home-server = self.nixosConfigurations.home-server.config.system.build.toplevel;
          vps = self.nixosConfigurations.vps.config.system.build.toplevel;
        };
      };
    };
}
