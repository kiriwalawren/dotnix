{
  pkgs,
  config,
  lib,
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
    home.packages = [ pkgs.wofi ];
    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER,Space,exec,${pkgs.wofi}/bin/wofi --show drun"
      ];
    };

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
        font-family: "${config.theme.font}", monospace;
        font-size: ${toString config.theme.fontSize}px;
      }

      window {
        margin: 0px;
        padding: 0px;
        border-radius: ${toString config.theme.radius}px;
        background-color: transparent;
      }

      #input {
        padding: 8px 12px;
        margin: 8px;
        border-radius: ${toString (config.theme.radius - 2)}px;
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
        border-radius: ${toString config.theme.radius}px;
        background: linear-gradient(#${config.catppuccin.colors.base}, #${config.catppuccin.colors.base}) padding-box,
                    linear-gradient(45deg, #${config.catppuccin.colors.primaryAccent}, #${config.catppuccin.colors.secondaryAccent}, #${config.catppuccin.colors.tertiaryAccent}) border-box;
      }

      #scroll {
        margin: 0px;
        padding: 5px;
        background-color: transparent;
      }

      #entry {
        padding: 8px;
        margin: 2px 0px;
        border-radius: ${toString (config.theme.radius - 4)}px;
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
  };
}
