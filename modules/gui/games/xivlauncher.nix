{
  flake.modules.homeManager.gaming =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.xivlauncher ];
    };

  flake.modules.homeManager.steamos =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.xivlauncher ];
    };
}
