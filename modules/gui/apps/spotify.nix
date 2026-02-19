{ inputs, ... }:
{
  nixpkgs.config.allowUnfreePackages = [ "spotify" ];
  flake.modules.nixos.gui = {
    networking.firewall.allowedUDPPorts = [
      5353
      1900
    ];
  };

  flake.modules.homeManager.gui =
    { config, pkgs, ... }:
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = [
        inputs.spicetify-nix.homeManagerModules.spicetify
      ];

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
