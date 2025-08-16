{lib, ...}: {
  meta.doc = lib.mdDoc ''
    Modern file explorer for Neovim that treats directories like buffers.

    Provides an intuitive file management experience:
    - Edit directories like normal Neovim buffers
    - Floating window interface for quick access
    - Hidden file support for complete directory visibility
    - Seamless integration with Neovim's editing capabilities
    - Replaces netrw as the default file explorer

    Accessible via leader+e for instant file navigation and manipulation.

    Links: [oil.nvim](https://github.com/stevearc/oil.nvim)
  '';

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
        action = "<cmd>Oil --float<cr>";
        options.desc = "Open Explorer";
      }
    ];
  };
}
