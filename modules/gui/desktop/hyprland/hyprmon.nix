{
  flake.modules.homeManager.hyprland =
    { pkgs, ... }:
    {
      wayland.windowManager.hyprland.settings = {
        bind = [
          "SUPER,M,exec,${pkgs.kitty}/bin/kitty --class=hyprmon ${pkgs.hyprmon}/bin/hyprmon"
        ];
      };
    };
}
