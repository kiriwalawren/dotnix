{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ui.apps.slack;
in {
  meta.doc = lib.mdDoc ''
    Slack desktop application for team communication.

    Installs the official [Slack](https://slack.com/) desktop client.
  '';

  options.ui.apps.slack = {
    enable = mkEnableOption (lib.mdDoc "Slack desktop application");
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [slack];
  };
}
