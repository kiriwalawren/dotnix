{
  flake.modules.nixvim.base.plugins = {
    lsp.servers.pylsp.enable = true;
    conform-nvim.settings.formatters_by_ft.python = [ "black" ];
  };

  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.black ];
    };
}
