{
  flake.modules.nixvim.base = {
    plugins.flash = {
      enable = true;
    };

    keymaps = [
      {
        mode = [
          "n"
          "x"
          "o"
        ];
        key = "s";
        action.__raw = "function() require'flash'.jump() end";
      }
      {
        mode = [
          "n"
          "x"
          "o"
        ];
        key = "S";
        action.__raw = "function() require'flash'.treesitter() end";
      }
      {
        mode = "o";
        key = "r";
        action.__raw = "function() require'flash'.remote() end";
      }
      {
        mode = [
          "o"
          "x"
        ];
        key = "R";
        action.__raw = "function() require'flash'.treesitter_search() end";
      }
    ];
  };
}
