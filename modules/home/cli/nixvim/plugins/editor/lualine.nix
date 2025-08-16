{lib, ...}: {
  meta.doc = lib.mdDoc ''
    Modern and customizable statusline for Neovim with clean aesthetics.

    Provides essential status information:
    - Current mode indication
    - File information and status
    - Git branch and changes
    - LSP diagnostics and status
    - Custom separators for clean appearance
    - Position and selection information

    Features a minimalist design with custom separators and seamless integration
    with other plugins for a cohesive editing experience.

    Links: [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
  '';

  programs.nixvim.plugins.lualine = {
    enable = true;

    settings = {
      options = {
        component_separators = {
          left = "";
          right = "";
        };

        section_separators = {
          left = "";
          right = "";
        };
      };

      sections = {
        lualine_a = [
          {
            separator.left = "";
          }
        ];
        lualine_z = [
          {
            separator.right = "";
          }
        ];
      };
    };
  };
}
