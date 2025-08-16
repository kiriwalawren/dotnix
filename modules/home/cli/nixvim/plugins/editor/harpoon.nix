{lib, ...}: {
  meta.doc = lib.mdDoc ''
    Quick file navigation system for managing frequently accessed files.

    Provides efficient project navigation:
    - Mark important files for instant access
    - Quick menu for file list management
    - Numbered shortcuts for up to 4 favorite files
    - Telescope integration for enhanced file browsing
    - Persistent file lists across sessions
    - Navigation between marked files with prev/next

    Uses leader+a to mark files, Ctrl+e for the quick menu, and Alt+a/o/e/u for slots 1-4.
    Essential for efficient project-based development workflow.

    Links: [harpoon](https://github.com/ThePrimeagen/harpoon)
  '';

  programs.nixvim = {
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
