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

  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.mapAttrs (
        name: _:
        pkgs.writeShellApplication {
          name = "deploy-${name}";

          runtimeInputs = [ pkgs.deploy-rs ];

          text = ''deploy .#${name} -s --remote-build "$@"'';
        }
      ) (lib.filterAttrs (_name: cfg: cfg.modules ? deploy) config.configurations.nixos);
    };

  flake.modules.nixos.deploy =
    { config, ... }:
    {
      users.users.${config.user.name}.extraGroups = [
        "wheel"
        "sudo"
      ];

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
}
