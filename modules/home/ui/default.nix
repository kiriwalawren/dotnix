{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.ui;
in {
  imports = [
    ../cli

    ./apps
    ./nixos

    ./fonts.nix
    ./cursors.nix
  ];

  meta.doc = lib.mdDoc ''
    UI module that enables user interface applications and theming.

    When enabled, automatically enables: cli, cursors, and apps.
    Also imports fonts and nixos UI modules for additional functionality.
  '';

  options.ui = {
    enable = mkEnableOption (lib.mdDoc "user interface applications and theming");
  };

  config = mkIf cfg.enable {
    cli.enable = true;
    ui = {
      cursors.enable = true;
      apps.enable = true;
    };
  };
}
