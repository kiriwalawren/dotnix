{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ui.nixos.gtk;
in {
  meta.doc = lib.mdDoc ''
    GTK theming with Colloid theme and Catppuccin styling.

    Configures [GTK](https://www.gtk.org/) with [Colloid theme](https://github.com/vinceliuice/Colloid-gtk-theme)
    in dark, compact variant with teal accents and Catppuccin integration.
    Includes matching [Colloid icon theme](https://github.com/vinceliuice/Colloid-icon-theme).
  '';

  options.ui.nixos.gtk = {
    enable = mkEnableOption (lib.mdDoc "GTK theming with Colloid and Catppuccin");
  };

  config = mkIf cfg.enable {
    xdg.enable = true;
    gtk = {
      enable = true;
      theme = {
        name = "Colloid-Teal-Dark-Compact-Catppuccin";
        package = pkgs.colloid-gtk-theme.override {
          themeVariants = ["teal"];
          colorVariants = ["dark"];
          sizeVariants = ["compact"];
          tweaks = ["catppuccin"];
        };
      };

      iconTheme = {
        package = pkgs.colloid-icon-theme;
        name = "Colloid-dark";
      };
    };
  };
}
