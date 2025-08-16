{lib, ...}: {
  meta.doc = lib.mdDoc ''
    Lightweight collection of essential Neovim utilities from mini.nvim.

    Provides fundamental editing enhancements:
    - Smart commenting with mini.comment for quick code commenting
    - Web devicons for file type visualization
    - Minimal configuration with maximum functionality
    - Fast and efficient implementation

    Focuses on core editing features without bloat, providing essential
    functionality for daily development tasks.

    Links: [mini.nvim](https://github.com/echasnovski/mini.nvim)
  '';

  programs.nixvim.plugins = {
    web-devicons.enable = true;

    mini = {
      enable = true;

      modules = {
        comment = {};
      };
    };
  };
}
