{
  flake.modules.homeManager.gui =
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

      programs.niri.settings.binds."Mod+Space".action.spawn = [ (lib.getExe pkgs.fuzzel) ];
    };
}
