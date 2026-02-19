{
  flake.modules.homeManager.gui =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      xdg.enable = true;
      gtk = {
        enable = true;
        theme = {
          name = "Colloid-Teal-Dark-Compact-Catppuccin";
          package = pkgs.colloid-gtk-theme.override {
            themeVariants = [ config.catppuccin.accent ];
            colorVariants = [ "dark" ];
            sizeVariants = [ "compact" ];
            tweaks = [ "catppuccin" ];
          };
        };

        iconTheme = lib.mkDefault {
          package = pkgs.yaru-theme;
          name = "Yaru-dark";
        };
      };
    };
}
