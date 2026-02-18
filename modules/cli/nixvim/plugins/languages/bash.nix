{
  flake.modules.nixvim.base.plugins = {
    lsp.servers.bashls.enable = true;

    conform-nvim = {
      settings = {
        formatters.shfmt.prepend_args = [
          "-i"
          "2"
          "-ci"
        ];

        formatters_by_ft.sh = [ "shfmt" ];
      };
    };
  };

  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.shfmt
      ];
    };
}
