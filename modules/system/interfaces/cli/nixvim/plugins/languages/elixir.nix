{
  flake.modules.nixvim.base.plugins = {
    lsp.servers.elixirls = {
      enable = true;
      settings = {
        elixirLS.mixEnv = "dev";
        elixirLS.dialyzerEnabled = true;
      };
    };

    conform-nvim.settings.formatters_by_ft.elixir = [ "mix" ];
  };
}
