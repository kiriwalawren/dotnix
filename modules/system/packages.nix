let
  getBasePackages =
    pkgs: with pkgs; [
      curl
      jq
    ];
in
{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      environment.systemPackages = getBasePackages pkgs;
    };

  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = getBasePackages pkgs;
    };
}
