{
  flake.modules.nixvim.base = {
    autoCmd = [
      {
        desc = "Automatically trim all whitespace an save";
        event = [ "BufWritePre" ];
        pattern = [ "*" ];
        command = ":%s/\\s\\+$//e";
      }
    ];

    keymaps = [
      {
        mode = [ "v" ];
        key = "<leader>o";
        action = ":sort<cr>";
        options.desc = "Sort Selected";
      }
    ];

    plugins.conform-nvim = {
      enable = true;

      settings = {
        notify_on_error = false;

        format_on_save = {
          lsp_fallback = "fallback";
          timeout_ms = 5000;
        };
      };
    };
  };

  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.prettierd ];
    };
}
