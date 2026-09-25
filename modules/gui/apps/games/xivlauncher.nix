{
  flake.modules.homeManager.ffxiv =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.xivlauncher ];
    };
}
