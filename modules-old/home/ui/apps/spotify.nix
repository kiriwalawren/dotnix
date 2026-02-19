{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.ui.apps.spotify;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    inputs.spicetify-nix.homeManagerModules.spicetify
  ];

  options.ui.apps.spotify = {
    enable = mkEnableOption "spotify";
  };

  config = mkIf cfg.enable {
    programs.spicetify = {
      enable = true;

      theme = spicePkgs.themes.catppuccin;

      colorScheme = config.catppuccin.flavor;

      enabledExtensions = with spicePkgs.extensions; [
        # Official extensions
        keyboardShortcut
        shuffle

        # Community extensions
        seekSong
        goToSong
        skipStats
        songStats
        autoVolume
        history
        hidePodcasts
        adblock
        savePlaylists
        playNext
        volumePercentage
      ];
    };
  };
}
