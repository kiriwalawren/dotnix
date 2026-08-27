{ inputs, config, ... }:
let
  spicetifyThemeName =
    {
      Catppuccin = "catppuccin";
      Nord = "nord";
      Tokyo-Night = "tokyoNight";
    }
    .${config.theme.colorSchemeName} or "default";
in
{
  nixpkgs.config.allowUnfreePackages = [ "spotify" ];
  flake.modules.nixos.gui = {
    networking.firewall.allowedUDPPorts = [
      5353
      1900
    ];
  };

  flake.modules.homeManager.gui =
    { pkgs, lib, ... }:
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = [
        inputs.spicetify-nix.homeManagerModules.spicetify
      ];

      programs.spicetify = {
        enable = true;

        theme = spicePkgs.themes.${spicetifyThemeName};
      }
      // lib.optionalAttrs (spicetifyThemeName == "catppuccin") {
        colorScheme = "mocha";
      }
      // {
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
