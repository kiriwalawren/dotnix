{ inputs, self, ... }:
{
  flake.modules.nixos.auto-deploy =
    { config, ... }:
    {
      sops.secrets."cachix/agent-token" = { };
      sops.templates."cachix-agent.env".content = ''
        CACHIX_AGENT_TOKEN="${config.sops.placeholder."cachix/agent-token"}"
      '';

      services.cachix-agent = {
        enable = true;
        credentialsFile = config.sops.templates."cachix-agent.env".path;
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
          homelab = self.nixosConfigurations.homelab.config.system.build.toplevel;
          vps = self.nixosConfigurations.vps.config.system.build.toplevel;
        };
      };
    };
}
