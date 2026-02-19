{ lib, ... }:
{
  options.theme = {
    defaultWallpaper = lib.mkOption {
      type = lib.types.path;
      default = ./_wallpapers/nixppuccin.png;
    };
    wallpapers = lib.mkOption {
      type = lib.types.path;
      readonly = true;
      default = ./_wallpapers;
    };
  };
}
