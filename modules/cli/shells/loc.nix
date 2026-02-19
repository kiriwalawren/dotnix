{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.scc ];
      programs.fish.shellAliases.loc = "scc --no-cocomo";
    };
}
