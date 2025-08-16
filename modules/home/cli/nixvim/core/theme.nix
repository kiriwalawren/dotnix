{lib, ...}: {
  meta.doc = lib.mdDoc ''
    Beautiful and modern color scheme configuration using Catppuccin theme.

    Provides aesthetic and functional theming:
    - Catppuccin color scheme with transparent background
    - Integrated plugin theming for consistent appearance
    - Support for multiple plugins (cmp, telescope, treesitter, gitsigns)
    - Enhanced visual experience with leap, flash, and mini integrations
    - Indent guides with colored levels for better code structure visibility

    Creates a cohesive and pleasing visual environment that reduces
    eye strain while maintaining excellent code readability.

    Links: [catppuccin](https://github.com/catppuccin/nvim)
  '';

  programs.nixvim.colorschemes.catppuccin = {
    enable = true;

    settings = {
      transparent_background = true;

      integrations = {
        cmp = true;
        flash = true;
        gitsigns = true;
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
