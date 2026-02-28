{ config, ... }:
{
  flake.modules.homeManager.hyprland = {
    catppuccin.mako.enable = true;

    services.mako = {
      enable = true;
      settings = {
        anchor = "bottom-right";
        border-radius = config.theme.radius;
        default-timeout = 10000; # 10s
        height = 300;
        width = 400;
      };
    };
  };
}
