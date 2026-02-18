{
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
