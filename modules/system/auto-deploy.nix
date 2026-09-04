{
  inputs,
  self,
  config,
  lib,
  ...
}:
let
  deployTargets = lib.filterAttrs (_name: cfg: cfg.modules ? auto-deploy) config.configurations.nixos;
in
{
  flake.modules.nixos.auto-deploy =
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

  flake.deploy.nodes = lib.mapAttrs (
    name: cfg:
    let
      system = self.nixosConfigurations.${name}.config.nixpkgs.hostPlatform.system;
      user = self.nixosConfigurations.${name}.config.user.name;
    in
    {
      groups = lib.optionals (cfg.modules ? auto-deploy) [ "auto-deploy" ];
      hostname = name;
      sshOpts = [
        "-o"
        "StrictHostKeyChecking=accept-new"
      ];
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
        lib.nameValuePair "deploy-${name}" (
          pkgs.writeShellApplication {
            name = "deploy-${name}";

            runtimeInputs = [ pkgs.deploy-rs ];

            text = ''${lib.getExe pkgs.deploy-rs} .#${name} --skip-checks --remote-build "$@"'';
          }
        )
      ) deployTargets;
    };
}
