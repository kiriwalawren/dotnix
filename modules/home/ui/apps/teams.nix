{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ui.apps.teams;
in {
  meta.doc = lib.mdDoc ''
    Teams for Linux desktop application for Microsoft Teams communication.

    Installs [Teams for Linux](https://github.com/IsmaelMartinez/teams-for-linux),
    an unofficial Linux client for Microsoft Teams.
  '';

  options.ui.apps.teams = {
    enable = mkEnableOption (lib.mdDoc "Teams for Linux desktop application");
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [teams-for-linux];
  };
}
