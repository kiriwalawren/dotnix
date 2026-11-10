{
  flake.modules.nixvim.base.plugins = {
    lsp.servers.marksman.enable = true;

    conform-nvim.settings = {
      formatters_by_ft.markdown = [ "mdformat" ];
      formatters.mdformat.condition = {
        __raw = ''
          function(self, ctx)
            local relative = vim.fn.fnamemodify(ctx.filename, ":.")
            return not relative:match("^docs/.*%.md$")
          end
        '';
      };
    };
  };
}
