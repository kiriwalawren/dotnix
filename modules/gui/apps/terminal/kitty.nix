{ config, ... }:
let
  bind = import ../../desktop/niri/_bind.nix;
in
{
  flake.wrappers.niri = { pkgs, lib, ... }: {
    settings.binds = {
      "Mod+Ctrl+Alt+Shift+Return" = bind "Terminal" { spawn = [ (lib.getExe pkgs.kitty) ]; };
      "Mod+Return" = bind "Terminal" { spawn = [ (lib.getExe pkgs.kitty) ]; };
    };
  };

  flake.modules.homeManager.gui = {
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
  };
}
