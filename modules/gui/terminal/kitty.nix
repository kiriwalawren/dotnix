{
  flake.modules.homeManager.gui =
    { config, ... }:
    {
      config = {
        catppuccin.kitty.enable = true;

        programs.kitty = {
          enable = true;

          font = {
            name = config.theme.font;
            size = config.theme.fontSize;
          };

          settings = {
            confirm_os_window_close = "0";
            copy_on_select = "clipboard";
            term = "xterm-256color";

            background_opacity = ".85";
          };
        };

        wayland.windowManager.hyprland.settings = {
          bind = [
            "SUPER,Return,exec,kitty"
          ];
        };
      };
    };
}
