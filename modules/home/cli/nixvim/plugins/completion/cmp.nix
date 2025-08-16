{lib, ...}: {
  meta.doc = lib.mdDoc ''
    Intelligent autocompletion for Neovim using nvim-cmp.

    Provides completion from multiple sources:
    - LSP servers for code completion
    - File paths for file navigation
    - Buffer content for context-aware suggestions
    - Command line completion

    Features smart navigation with Tab/Shift-Tab and Ctrl-J/K, instant completion with Ctrl-Space,
    and seamless integration with LSP and other completion sources.

    Links: [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
  '';

  programs.nixvim.plugins = {
    cmp-nvim-lsp.enable = true;
    cmp-buffer.enable = true;
    cmp-path.enable = true;
    cmp-cmdline.enable = true;

    cmp = {
      enable = true;

      settings = {
        sources = [
          {name = "nvim_lsp";}
          {name = "path";}
          {name = "buffer";}
        ];

        mapping = {
          "<C-n>" = "cmp.mapping.select_next_item()";
          "<C-p>" = "cmp.mapping.select_prev_item()";
          "<C-j>" = "cmp.mapping.select_next_item()";
          "<C-k>" = "cmp.mapping.select_prev_item()";
          "<C-d>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
          "<C-Space>" = "cmp.mapping.complete()";
          "<C-e>" = "cmp.mapping.close()";
          "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
          "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
          "<CR>" = "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = true })";
        };
      };
    };
  };
}
