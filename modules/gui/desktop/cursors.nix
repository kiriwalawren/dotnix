{
  flake.modules.homeManager.gui = {
    catppuccin.cursors.enable = true;

    home.pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      size = 24;
    };
  };
}
