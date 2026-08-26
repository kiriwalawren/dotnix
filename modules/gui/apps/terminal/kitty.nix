{ config, ... }:
{
  flake.wrappers.niri =
    { pkgs, lib, ... }:
    {
      settings.binds."Mod+Return".spawn = [ (lib.getExe pkgs.kitty) ];
    };

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
        };
      };

      wayland.windowManager.hyprland.settings.bind = [ "SUPER,Return,exec,${lib.getExe pkgs.kitty}" ];
    };
}
