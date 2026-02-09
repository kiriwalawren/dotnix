{
  hostConfig,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.ui;
in
{
  imports = [
    ../cli

    ./apps
    ./nixos

    ./cursors.nix
  ];

  options.ui = {
    enable = mkEnableOption "ui";
  };

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = hostConfig.fonts.fontconfig.enable;
    cli.enable = true;
    ui = {
      cursors.enable = true;
      apps.enable = true;
    };
  };
}
