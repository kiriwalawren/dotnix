{
  programs.nixvim = {
    plugins.oil = {
      enable = true;

      settings = {
        default_file_explorer = true;

        float = {
          max_height = 25;
          max_width = 75;
        };

        view_options.show_hidden = true;
      };
    };

    keymaps = [
      {
        mode = ["n"];
        key = "<leader>e";
        action = "<cmd>lua if vim.bo.filetype == 'oil' then vim.cmd('bd') else require('oil').open_float() end<cr>";
        options.desc = "Toggle Explorer";
      }
    ];
  };
}
