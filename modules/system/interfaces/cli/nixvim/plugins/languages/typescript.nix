{
  flake.modules.nixvim.base.plugins = {
    lsp.servers.ts_ls.enable = true;

    conform-nvim.settings.formatters_by_ft.typescript = {
      __unkeyed-1 = "prettierd";
      __unkeyed-2 = "prettier";
      stop_after_first = true;
    };
    conform-nvim.settings.formatters_by_ft.typescriptreact = {
      __unkeyed-1 = "prettierd";
      __unkeyed-2 = "prettier";
      stop_after_first = true;
    };
  };
}
