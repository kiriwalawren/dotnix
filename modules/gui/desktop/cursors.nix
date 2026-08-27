{
  flake.modules.homeManager.gui =
    { pkgs, ... }:
    {
      home.pointerCursor = {
        enable = true;
        gtk.enable = true;
        x11.enable = true;
        size = 24;
        package = pkgs.phinger-cursors;
        name = "phinger-cursors-dark";
      };
    };
}
