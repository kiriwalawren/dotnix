{
  flake.modules.nixvim.base = {
    plugins.harpoon = {
      enable = true;
      enableTelescope = true;

      settings.settings = {
        save_on_toggle = true;
        sync_on_ui_close = true;
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>a";
        action.__raw = "function() require'harpoon':list():add() end";
      }
      {
        mode = "n";
        key = "<C-e>";
        action.__raw = "function() require'harpoon'.ui:toggle_quick_menu(require'harpoon':list()) end";
      }
      {
        mode = "n";
        key = "<A-a>";
        action.__raw = "function() require'harpoon':list():select(1) end";
      }
      {
        mode = "n";
        key = "<A-o>";
        action.__raw = "function() require'harpoon':list():select(2) end";
      }
      {
        mode = "n";
        key = "<A-e>";
        action.__raw = "function() require'harpoon':list():select(3) end";
      }
      {
        mode = "n";
        key = "<A-u>";
        action.__raw = "function() require'harpoon':list():select(4) end";
      }
      {
        mode = "n";
        key = "<leader>p";
        action.__raw = "function() require'harpoon':list():prev() end";
      }
      {
        mode = "n";
        key = "<leader>n";
        action.__raw = "function() require'harpoon':list():next() end";
      }
    ];
  };
}
