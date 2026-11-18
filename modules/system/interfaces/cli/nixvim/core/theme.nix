{
  flake.modules.nixvim.base.colorschemes.catppuccin = {
    enable = true;

    settings = {
      flavor = "mocha";

      transparent_background = true;
      float.transparent = true;

      integrations = {
        cmp = true;
        flash = true;
        gitsigns = true;
        harpoon = true;
        leap = true;
        mini.enabled = true;
        telescope.enabled = true;
        treesitter = true;
        treesitter_context = true;
        indent_blankline = {
          enable = true;
          colored_indent_levels = true;
        };
      };
    };
  };
}
