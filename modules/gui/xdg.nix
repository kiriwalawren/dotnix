{
  flake.modules.nixos.gui =
    { pkgs, ... }:
    {
      xdg = {
        autostart.enable = true;
        portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
          config.common.default = [ "gtk" ];
        };
      };
    };
}
