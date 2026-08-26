{
  flake.modules.homeManager.gui =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        darktable
        # This one doesn't build. Removing it for now.
        # gimp2-with-plugins
        rapidraw
      ];
    };
}
