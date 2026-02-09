{
  pkgs,
  config,
  lib,
  theme,
  ...
}:
with lib;
with builtins;
let
  cfg = config.ui.nixos.wofi;
in
{
  options.ui.nixos.wofi = {
    enable = mkEnableOption "wofi";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ wofi ];

    xdg.configFile."wofi/config".text = ''
      width=600
      height=400
      location=center
      show=drun
      prompt=Search...
      filter_rate=100
      allow_markup=true
      no_actions=true
      halign=fill
      orientation=vertical
      content_halign=fill
      insensitive=true
      allow_images=true
      image_size=32
      gtk_dark=true
    '';

    xdg.configFile."wofi/style.css".text = ''
      * {
        font-family: "${theme.font}", monospace;
        font-size: ${toString theme.fontSize}px;
      }

      window {
        margin: 0px;
        padding: 0px;
        border-radius: ${toString theme.radius}px;
        background-color: transparent;
      }

      #input {
        padding: 8px 12px;
        margin: 8px;
        border-radius: ${toString (theme.radius - 2)}px;
      }

      #input:focus { }

      #inner-box {
        margin: 5px;
        padding: 5px;
      }

      #outer-box {
        margin: 0px;
        padding: 10px;
        border: 2px solid transparent;
        border-radius: ${toString theme.radius}px;
        background: linear-gradient(#${theme.colors.base}, #${theme.colors.base}) padding-box,
                    linear-gradient(45deg, #${theme.colors.primaryAccent}, #${theme.colors.secondaryAccent}, #${theme.colors.tertiaryAccent}) border-box;
      }

      #scroll {
        margin: 0px;
        padding: 5px;
        background-color: transparent;
      }

      #entry {
        padding: 8px;
        margin: 2px 0px;
        border-radius: ${toString (theme.radius - 4)}px;
      }

      #entry:selected {
      }

      #entry:hover {
      }

      #text {
        margin: 0px 8px;
      }

      #entry:selected #text {
        font-weight: bold;
      }

      #img {
        margin-right: 8px;
      }
    '';

    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER,Space,exec,wofi --show drun"
      ];
    };
  };
}
