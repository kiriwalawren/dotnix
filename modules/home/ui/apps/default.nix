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
    ./vesktop
  ];

  options.ui.apps = {enable = mkEnableOption "apps";};

  config = mkIf cfg.enable {
    ui.apps = {
      firefox.enable = true;
      kitty.enable = true;
      slack.enable = true;
      spotify.enable = true;
      teams.enable = true;
      vesktop.enable = true;
    };
  };
}
