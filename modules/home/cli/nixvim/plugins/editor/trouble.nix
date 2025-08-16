{lib, ...}: {
  meta.doc = lib.mdDoc ''
    Enhanced diagnostic and problem management for Neovim development.

    Provides comprehensive issue tracking and navigation:
    - Unified diagnostics view for all project issues
    - Buffer-specific diagnostic filtering
    - LSP symbol and reference navigation
    - Integration with quickfix and location lists
    - Document symbol browsing and workspace navigation
    - Efficient problem resolution workflow

    Features extensive keybindings for quick access to diagnostics, symbols,
    and references, making debugging and code navigation seamless.

    Links: [trouble.nvim](https://github.com/folke/trouble.nvim)
  '';

  programs.nixvim = {
    plugins.trouble = {
      enable = true;

      settings = {
        warn_no_results = false;
      };
    };

    keymaps = [
      {
        mode = ["n"];
        key = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle<cr>";
        options.desc = "Diagnostics (Trouble)";
      }
      {
        mode = ["n"];
        key = "<leader>xX";
        action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
        options.desc = "Buffer Diagnostics (Trouble)";
      }
      {
        mode = ["n"];
        key = "<leader>cs";
        action = "<cmd>Trouble symbols toggle focus=false<cr>";
        options.desc = "Symbols (Trouble)";
      }
      {
        mode = ["n"];
        key = "<leader>xl";
        action = "<cmd>Trouble loclist toggle<cr>";
        options.desc = "Location List (Trouble)";
      }
      {
        mode = ["n"];
        key = "<leader>xq";
        action = "<cmd>Trouble qflist toggle<cr>";
        options.desc = "Quickfix List (Trouble)";
      }
      {
        mode = ["n"];
        key = "gR";
        action = "<cmd>Trouble lsp toggle focus=false win.position=right<cr>";
        options.desc = "LSP Definitons / references / ... (Trouble)";
      }
      {
        mode = ["n"];
        key = "[q";
        action.__raw = "vim.cmd.cprev";
        options.desc = "Prev quickfix";
      }
      {
        mode = ["n"];
        key = "]q";
        action.__raw = "vim.cmd.cnext";
        options.desc = "Next quickfix";
      }
    ];
  };
}
