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
            "https://cache.walawren.com"
            "https://niri.cachix.org"
            "https://catppuccin.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "kiriwalawrencache:El6x5MaDGiJQo5NocuCflnxRf5M/XLsfbIANrdJKkrE="
            "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
            "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
          ];
        };
      };
    };
}
