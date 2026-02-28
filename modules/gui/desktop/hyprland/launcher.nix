{
  flake.modules.homeManager.hyprland =
    { pkgs, lib, ... }:
    {
      home.packages = [ pkgs.fuzzel ];

      catppuccin.fuzzel.enable = true;

      programs.fuzzel = {
        enable = true;
      };

      wayland.windowManager.hyprland.settings = {
        bind = [
          "SUPER,Space,exec,${lib.getExe pkgs.fuzzel}"
        ];
      };
    };
}
