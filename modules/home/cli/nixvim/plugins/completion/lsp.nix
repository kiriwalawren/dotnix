{lib, ...}: {
  meta.doc = lib.mdDoc ''
    Language Server Protocol (LSP) integration with comprehensive language support.

    Provides intelligent code features including:
    - Multi-language LSP servers (Elixir, TypeScript, Nix, JSON, Markdown)
    - Code navigation (go to definition, references, type definition)
    - Real-time diagnostics and error checking
    - Code actions and refactoring
    - Symbol renaming across files
    - Hover documentation
    - None-ls integration for additional tooling

    Includes keybindings for efficient code navigation and manipulation.

    Links: [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig), [none-ls](https://github.com/nvimtools/none-ls.nvim)
  '';

  programs.nixvim.plugins = {
    none-ls.enable = true;
    lsp = {
      enable = true;

      servers = {
        # dockerls.enable = true;
        elixirls = {
          enable = true;
          settings = {
            elixirLS.mixEnv = "dev";
            elixirLS.dialyzerEnabled = true;
          };
        };
        # gopls.enable = true;
        jsonls.enable = true;
        marksman.enable = true;
        nil_ls.enable = true; # Nix
        ts_ls.enable = true;
        # omnisharp.enable = true;
      };
      keymaps = {
        lspBuf = {
          "gd" = {
            action = "definition";
            desc = "Goto Definitions";
          };
          "gr" = {
            action = "rename";
            desc = "Rename text across file";
          };
          "gD" = {
            action = "references";
            desc = "Goto References";
          };
          "gt" = {
            action = "type_definition";
            desc = "Goto Type Definitions";
          };
          "gi" = {
            action = "implementation";
            desc = "Goto implementation";
          };
          "K" = "hover";
          "<leader>ca" = {
            action = "code_action";
            desc = "Code Actions";
          };
        };
        diagnostic = {
          "<leader>dd" = {
            action = "open_float";
            desc = "Open Diagnostic List";
          };
          "<leader>d[" = {
            action = "goto_next";
            desc = "Goto Next Issue";
          };
          "<leader>d]" = {
            action = "goto_prev";
            desc = "Goto Prev Issue";
          };
        };
      };
    };
  };
}
