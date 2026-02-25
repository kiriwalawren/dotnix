{
  nixpkgs.config.allowUnfreePackages = [ "claude-code" ];

  flake.modules.homeManager.cli =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.claude-code ];
    };
}
