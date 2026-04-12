{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.tokei ];
      programs.fish.shellAliases.loc = "tokei";
    };
}
