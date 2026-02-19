{
  flake.modules.nixos.gui =
    { pkgs, ... }:
    {
      catppuccin.plymouth.enable = true;

      boot.plymouth = {
        enable = true;
        font = "${pkgs.maple-mono.NF}/share/fonts/truetype/MapleMono-NF-Regular.ttf";
      };
    };
}
