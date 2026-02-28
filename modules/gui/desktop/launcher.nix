{
  flake.modules.homeManager.gui =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.fuzzel ];

      catppuccin.fuzzel.enable = true;

      programs.fuzzel = {
        enable = true;
      };

      wayland.windowManager.hyprland.settings = {
        bind = [
          "SUPER,Space,exec,${pkgs.fuzzel}/bin/fuzzel"
        ];
      };
    };
}
