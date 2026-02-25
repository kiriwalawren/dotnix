{ config, ... }:
{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.cachix
      ];

      nix = {
        settings = {
          trusted-users = [
            "root"
            config.user.name
          ];

          substituters = [
            "https://cache.nixos.org"
            "https://kiriwalawren.cachix.org"
            "https://niri.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "kiriwalawren.cachix.org-1:a4EdChIG5Si1mIBrWfXn1g4ikinyO2jyycgwEds9eBQ="
            "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
          ];
        };
      };
    };
}
