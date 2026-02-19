{
  flake.modules.homeManager.gui =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.loupe ];
    };
}
