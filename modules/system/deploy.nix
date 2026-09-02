{
  inputs,
  self,
  config,
  lib,
  ...
}:
let
  deployTargets = lib.filterAttrs (_name: cfg: cfg.modules ? deploy) config.configurations.nixos;
in
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
  ) deployTargets;

  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.mapAttrs' (
        name: _:
        lib.nameValuePair ("deploy-" + name) (
          pkgs.writeShellApplication {
            name = "deploy-${name}";

            runtimeInputs = [ pkgs.deploy-rs ];

            text = ''deploy .#${name} --skip-checks --remote-build --dry-activate "$@"'';
          }
        )
      ) deployTargets;
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
