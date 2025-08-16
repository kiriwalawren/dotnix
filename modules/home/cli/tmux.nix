{
  config,
  hostConfig,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.cli.tmux;
in {
  meta.doc = lib.mdDoc ''
    Terminal multiplexer configuration with vi-style keybindings.

    Provides [tmux](https://github.com/tmux/tmux/wiki) with a comprehensive setup including:
    - Vi-style key bindings and navigation
    - Custom pane navigation and resizing
    - Mouse support and 24-bit color
    - [Catppuccin](https://github.com/catppuccin/tmux) theme with custom icons
    - Automatic window titles and 10k line history
  '';

  options.cli.tmux = {
    enable = mkEnableOption (lib.mdDoc "terminal multiplexer with vi-style keybindings");
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      shortcut = "a";
      terminal = "xterm-256color";
      baseIndex = 1;
      keyMode = "vi"; # VI Mode
      customPaneNavigationAndResize = true; # Override hjkl and HJKL bindings for pane navigation and resizing VI Mode
      historyLimit = 10000;
      mouse = true;

      extraConfig = ''
        # Automatically set window titles
        set-window-option -g automatic-rename on
        set-option -g set-titles on

        # Enable 24-bit "True color" support
        set-option -ga terminal-overrides ",xterm-256color:Tc"
      '';

      plugins = with pkgs; [
        {
          plugin = tmuxPlugins.catppuccin;
          extraConfig = ''
            set -g @catppuccin-flavor "mocha"
            set -g @catppuccin_icon_window_last "󰖰 "
            set -g @catppuccin_icon_window_current "󰖯 "
            set -g @catppuccin_icon_window_zoom "󰁌 "
            set -g @catppuccin_icon_window_mark "󰃀 "
            set -g @catppuccin_icon_window_silent "󰂛 "
            set -g @catppuccin_icon_window_activity "󱅫 "
            set -g @catppuccin_icon_window_bell "󰂞 "
          '';
        }
      ];
    };
  };
}
