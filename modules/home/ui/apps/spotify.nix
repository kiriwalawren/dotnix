{
  lib,
  config,
  pkgs,
  inputs,
  theme,
  ...
}:
with lib; let
  cfg = config.ui.apps.spotify;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
in {
  imports = [
    inputs.spicetify-nix.homeManagerModules.spicetify
  ];

  meta.doc = lib.mdDoc ''
    Spotify music streaming client with Spicetify theming and extensions.

    Configures [Spotify](https://www.spotify.com/us/download/linux/) with [Spicetify](https://spicetify.app/)
    customizations including Catppuccin theme and productivity extensions for
    enhanced functionality and appearance.
  '';

  options.ui.apps.spotify = {
    enable = mkEnableOption (lib.mdDoc "Spotify with Spicetify theming");
  };

  config = mkIf cfg.enable {
    programs.spicetify = {
      enable = true;

      theme = spicePkgs.themes.catppuccin;

      colorScheme = theme.variant;

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
