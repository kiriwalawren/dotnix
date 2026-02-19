{ config, lib, ... }:
let
  getFonts =
    pkgs: with pkgs; [
      maple-mono.variable
      nerd-fonts.fira-code
      inter
      source-serif
    ];
in
{
  options.theme = {
    font = lib.mkOption {
      type = lib.types.str;
      default = "Maple Mono";
    };
    fontSizeSmall = lib.mkOption {
      type = lib.types.number;
      default = 12;
    };
    fontSize = lib.mkOption {
      type = lib.types.number;
      default = 14;
    };
  };

  config = {
    flake.modules.nixos.base =
      { pkgs, ... }:
      {
        fonts.packages = getFonts pkgs;
      };

    flake.modules.homeManager.base =
      { pkgs, ... }:
      {
        home.packages = getFonts pkgs;
        fonts.fontconfig = {
          enable = true;
          hinting = "slight";
          antialiasing = true;
          defaultFonts = {
            monospace = [
              config.theme.font
              "Fira Code"
            ];
            sansSerif = [ "Inter" ];
            serif = [ "Source Serif 4" ];
          };
        };
      };
  };
}
