{
  flake.modules.nixvim.base.plugins = {
    lsp.servers.gopls.enable = true;

    conform-nvim.settings.formatters_by_ft.go = [ "gofmt" ];
  };
}
