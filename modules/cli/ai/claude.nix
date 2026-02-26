{
  nixpkgs.config.allowUnfreePackages = [ "claude-code" ];

  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.claude-code ];
    };
}
