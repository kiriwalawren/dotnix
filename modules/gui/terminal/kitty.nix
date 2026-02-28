{ config, ... }:
{
  flake.modules.homeManager.gui =
    { lib, pkgs, ... }:
    {
      catppuccin.kitty.enable = true;

      programs.kitty = {
        enable = true;

        font = {
          name = config.theme.font;
          size = config.theme.fontSize;
        };

        settings = {
          enable_audio_bell = "no";
          confirm_os_window_close = "0";
          copy_on_select = "clipboard";
          term = "xterm-256color";

          background_opacity = ".85";
        };
      };

      wayland.windowManager.hyprland.settings.bind = [ "SUPER,Return,exec,${lib.getExe pkgs.kitty}" ];

      programs.niri.settings.binds."Mod+Return".action.spawn = [ (lib.getExe pkgs.kitty) ];
    };
}
