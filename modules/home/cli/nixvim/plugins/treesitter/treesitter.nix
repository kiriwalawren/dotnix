{lib, ...}: {
  meta.doc = lib.mdDoc ''
    Advanced syntax highlighting and code understanding using Tree-sitter.

    Provides intelligent code parsing and highlighting:
    - Precise syntax highlighting for multiple languages
    - Intelligent code indentation based on syntax structure
    - Foundation for advanced text manipulation and navigation
    - Real-time parsing for immediate feedback
    - Support for complex language constructs

    Essential plugin that powers many other Neovim features like text objects,
    navigation, and code understanding throughout the editor.

    Links: [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
  '';

  programs.nixvim.plugins.treesitter = {
    enable = true;

    settings = {
      indent.enable = true;
      highlight.enable = true;
    };
  };
}
