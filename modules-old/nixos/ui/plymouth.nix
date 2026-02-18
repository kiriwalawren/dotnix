{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.ui.plymouth;
in
{
  options.ui.plymouth = {
    enable = mkEnableOption "plymouth";
  };

  config = mkIf cfg.enable {
    catppuccin.plymouth.enable = true;

    boot.plymouth = {
      enable = true;
      font = "${pkgs.maple-mono.NF}/share/fonts/truetype/MapleMono-NF-Regular.ttf";
    };
  };
}
