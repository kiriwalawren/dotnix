{
  flake.modules.nixvim.base.plugins = {
    conform-nvim.settings.formatters_by_ft.javascript = {
      __unkeyed-1 = "prettierd";
      __unkeyed-2 = "prettier";
      stop_after_first = true;
    };
    conform-nvim.settings.formatters_by_ft.javascriptreact = {
      __unkeyed-1 = "prettierd";
      __unkeyed-2 = "prettier";
      stop_after_first = true;
    };
  };
}
