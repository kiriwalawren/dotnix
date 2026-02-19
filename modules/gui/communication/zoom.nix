{
  nixpkgs.config.allowUnfreePackages = [ "zoom" ];

  flake.modules.homeManager.gui =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.zoom-us ];
    };
}
