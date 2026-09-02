{
  inputs,
  self,
  config,
  lib,
  ...
}:
{
  flake.deploy.nodes = lib.mapAttrs (
    name: _:
    let
      system = self.nixosConfigurations.${name}.config.nixpkgs.hostPlatform.system;
      user = self.nixosConfigurations.${name}.config.user.name;
    in
    {
      hostname = name;
      profiles.system = {
        user = "root";
        sshUser = user;
        path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.${name};
      };
    }
  ) (lib.filterAttrs (_name: cfg: cfg.modules ? deploy) config.configurations.nixos);

  flake.modules.nixos.deploy =
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

      # Required for deploy-rs
      users.users.${config.user.name}.extraGroups = [
        "wheel"
        "sudo"
      ];

      # Required for deploy-rs
      security.sudo.extraRules = [
        {
          groups = [ "wheel" ];
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
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
