{
  pkgs,
  lib,
  config,
  theme,
  ...
}:
with lib; let
  cfg = config.ui.plymouth;
in {
  options.ui.plymouth = {enable = mkEnableOption "plymouth";};

  config = mkIf cfg.enable {
    boot.plymouth = {
      enable = true;
      font = "${pkgs.maple-mono.NF}/share/fonts/truetype/MapleMono-NF-Regular.ttf";

      themePackages = [
        (pkgs.catppuccin-plymouth.override {
          inherit (theme) variant;
        })
      ];
      theme = theme.name;
    };
  };
}
