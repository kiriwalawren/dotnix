{
  flake.modules.homeManager.base = {
    catppuccin.tmux.enable = true;

    programs.tmux = {
      enable = true;
      shortcut = "a";
      terminal = "xterm-256color";
      baseIndex = 1;
      keyMode = "vi"; # VI Mode
      historyLimit = 10000;
      mouse = true;

      extraConfig = ''
        # Automatically set window titles
        set-window-option -g automatic-rename on
        set-option -g set-titles on

        # Enable 24-bit "True color" support
        set-option -ga terminal-overrides ",xterm-256color:Tc"

        # Easy last-window
        bind -T prefix -r C-a last-window
        set -g repeat-time 300   # milliseconds; adjust to taste

        # Allow (n)vim to see TMUX focus events
        set -g focus-events on
      '';
    };
  };
}
