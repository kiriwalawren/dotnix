{
  flake.modules.nixvim.base.plugins.conform-nvim = {
    enable = true;

    settings = {
      notify_on_error = false;

      format_on_save = {
        lsp_fallback = "fallback";
        timeout_ms = 5000;
      };
    };
  };

  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.prettierd ];
    };
}
