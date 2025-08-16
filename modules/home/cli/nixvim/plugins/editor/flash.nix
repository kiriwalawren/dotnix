{lib, ...}: {
  meta.doc = lib.mdDoc ''
    Fast navigation plugin for Neovim using labeled jumps and treesitter integration.

    Provides lightning-fast cursor movement:
    - Character-based jumping with visible labels
    - Treesitter-aware navigation for code structure
    - Remote operation support for distant targets
    - Enhanced search functionality with treesitter
    - Jump labels for improved visibility

    Uses 's' for basic jumps, 'S' for treesitter jumps, and 'r'/'R' for remote operations.
    Significantly speeds up navigation within buffers.

    Links: [flash.nvim](https://github.com/folke/flash.nvim)
  '';

  programs.nixvim = {
    plugins.flash = {
      enable = true;

      settings = {
        modes.char.jumpLabels = true;
      };
    };

    keymaps = [
      {
        mode = [
          "n"
          "x"
          "o"
        ];
        key = "s";
        action.__raw = "function() require'flash'.jump() end";
      }
      {
        mode = [
          "n"
          "x"
          "o"
        ];
        key = "S";
        action.__raw = "function() require'flash'.treesitter() end";
      }
      {
        mode = "o";
        key = "r";
        action.__raw = "function() require'flash'.remote() end";
      }
      {
        mode = [
          "o"
          "x"
        ];
        key = "R";
        action.__raw = "function() require'flash'.treesitter_search() end";
      }
    ];
  };
}
