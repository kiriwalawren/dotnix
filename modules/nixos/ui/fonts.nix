{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ui.fonts;
in {
  options.ui.fonts = {enable = mkEnableOption "fonts";};

  config = mkIf cfg.enable {
    fonts.packages = with pkgs; [
      nerd-fonts.fira-code
      maple-mono.variable
      inter
      source-serif
    ];

    fonts.fontconfig = {
      enable = true;
      hinting = {
        enable = true;
        style = "slight";
      };
      antialias = true;
      defaultFonts = {
        monospace = ["Maple Mono" "Fira Code"];
        sansSerif = ["Inter"];
        serif = ["Source Serif 4"];
      };
    };
  };
}
