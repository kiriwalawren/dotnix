{pkgs, ...}: {
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
}
