{lib, ...}: {
  meta.doc = lib.mdDoc ''
    Smart text objects for code navigation using Tree-sitter syntax awareness.

    Provides intelligent code structure navigation:
    - Function-based text objects for quick function navigation
    - Class-based text objects for object-oriented code
    - Syntax-aware movement between code constructs
    - Next/previous navigation for functions and classes
    - Bracket navigation for start and end of code blocks

    Uses ]f/[f for function navigation and ]c/[c for class navigation,
    with uppercase variants for moving to the end of constructs.

    Links: [nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects)
  '';

  programs.nixvim.plugins.treesitter-textobjects = {
    enable = true;
    move = {
      enable = true;

      gotoNextStart = {
        "]f" = "@function.outer";
        "]c" = "@class.outer";
      };
      gotoNextEnd = {
        "]F" = "@function.outer";
        "]C" = "@class.outer";
      };
      gotoPreviousStart = {
        "[f" = "@function.outer";
        "[c" = "@class.outer";
      };
      gotoPreviousEnd = {
        "[F" = "@function.outer";
        "[C" = "@class.outer";
      };
    };
  };
}
