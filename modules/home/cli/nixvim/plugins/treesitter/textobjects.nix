{
  programs.nixvim.plugins.treesitter-textobjects = {
    enable = true;
    settings.move = {
      enable = true;

      goto_next_start = {
        "]f" = "@function.outer";
        "]c" = "@class.outer";
      };
      goto_next_end = {
        "]F" = "@function.outer";
        "]C" = "@class.outer";
      };
      goto_previous_start = {
        "[f" = "@function.outer";
        "[c" = "@class.outer";
      };
      goto_previous_end = {
        "[F" = "@function.outer";
        "[C" = "@class.outer";
      };
    };
  };
}
