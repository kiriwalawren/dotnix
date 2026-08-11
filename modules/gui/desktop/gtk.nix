{
  flake.modules.homeManager.gui =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    # TODO: readd when https://github.com/NixOS/nixpkgs/pull/547916 is merged
    # let
    #   capitalize =
    #     s:
    #     let
    #       len = builtins.stringLength s;
    #     in
    #     if len == 0 then
    #       ""
    #     else
    #       let
    #         first = lib.toUpper (builtins.substring 0 1 s);
    #         rest = builtins.substring 1 (len - 1) s;
    #       in
    #       first + rest;
    # in
    {
      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

      xdg.enable = true;
      gtk = {
        enable = true;
        gtk4.theme = config.gtk.theme;
        # TODO: readd when https://github.com/NixOS/nixpkgs/pull/547916 is merged
        # theme = {
        #   name = "Catppuccin-GTK-${capitalize config.catppuccin.accent}-Dark-Compact";
        #   package = pkgs.magnetic-catppuccin-gtk.override {
        #     acccent = [ config.catppuccin.accent ];
        #     shade = "dark";
        #     colorVariants = [ "dark" ];
        #     size = "compact";
        #   };
        # };

        iconTheme = lib.mkDefault {
          package = pkgs.yaru-theme;
          name = "Yaru-dark";
        };
      };
    };
}
