{
  flake.modules.homeManager.gui =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

      xdg.enable = true;
      gtk = {
        enable = true;
        gtk4.theme = config.gtk.theme;
        theme = {
          name = "adw-gtk3";
          package = pkgs.adw-gtk3;
        };

        gtk3.extraCss = ''@import url("noctalia.css");'';
        gtk4.extraCss = ''@import url("noctalia.css");'';

        iconTheme = lib.mkDefault {
          package = pkgs.yaru-theme;
          name = "Yaru-dark";
        };
      };
    };
}
