{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.cli.direnv;
in {
  meta.doc = lib.mdDoc ''
    Automatic environment switching for development projects.

    Enables [direnv](https://direnv.net/) with [nix-direnv](https://github.com/nix-community/nix-direnv)
    integration to automatically load development environments when entering project directories.
    Perfect for managing project-specific dependencies and environment variables.
  '';

  options.cli.direnv = {
    enable = mkEnableOption (lib.mdDoc "automatic development environment switching with direnv");
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
