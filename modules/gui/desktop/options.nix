{ lib, ... }:
{
  options.desktop = {
    windowManager = lib.mkOption {
      type = lib.types.enum [ "hyprland" ];
      default = "hyprland";
      description = "Which desktop environment to use.";
    };
  };
}
