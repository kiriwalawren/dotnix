{
  flake.modules.nixos.gui = { lib, pkgs, ... }: {
    # switch-to-configuration-ng restarts user units mid-switch; restarting the portals
    # hangs the session (and the switch). Pick up portal updates on next login instead.
    systemd.user.services =
      lib.genAttrs [ "xdg-desktop-portal" "xdg-desktop-portal-gtk" "xdg-desktop-portal-gnome" ]
        (_: {
          restartIfChanged = false;
          enableDefaultPath = false;
        });

    xdg = {
      autostart.enable = true;
      portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-gnome
        ];
      };
    };
  };
}
