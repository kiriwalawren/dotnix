{lib, ...}: {
  meta.doc = lib.mdDoc ''
    Git integration for Neovim with visual indicators and blame information.

    Provides comprehensive Git status visualization:
    - Line-level change indicators in the sign column
    - Real-time diff highlighting for added, changed, and deleted lines
    - Current line blame annotations for authorship tracking
    - Integration with Trouble plugin for enhanced diagnostics
    - Visual indicators for untracked files

    Shows Git changes directly in the editor for immediate feedback on modifications.

    Links: [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)
  '';

  programs.nixvim.plugins.gitsigns = {
    enable = true;
    settings = {
      trouble = true;
      current_line_blame = true;
      signs = {
        add = {
          text = "│";
        };
        change = {
          text = "│";
        };
        delete = {
          text = "_";
        };
        topdelete = {
          text = "‾";
        };
        changedelete = {
          text = "~";
        };
        untracked = {
          text = "│";
        };
      };
    };
  };
}
