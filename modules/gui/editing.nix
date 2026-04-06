{
  flake.modules.homeManager.gui =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        darktable
        gimp2-with-plugins
        rapidraw
      ];
    };
}
