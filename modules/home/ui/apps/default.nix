{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.ui.apps;
in {
  imports = [
    ./firefox.nix
    ./kitty.nix
    ./slack.nix
    ./spotify.nix
    ./teams.nix
    ./vencord
  ];

  meta.doc = lib.mdDoc ''
    UI applications module that enables common desktop applications.

    When enabled, automatically enables: firefox, kitty, slack, spotify, teams, and vencord.
    Provides a curated set of applications for web browsing, terminal, communication, and media.
  '';

  options.ui.apps = {
    enable = mkEnableOption (lib.mdDoc "common desktop applications");
  };

  config = mkIf cfg.enable {
    ui.apps = {
      firefox.enable = true;
      kitty.enable = true;
      slack.enable = true;
      spotify.enable = true;
      teams.enable = true;
      vencord.enable = true;
    };
  };
}
