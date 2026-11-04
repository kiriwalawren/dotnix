{ lib, ... }: {
  options.theme = {
    defaultWallpaper = lib.mkOption {
      type = lib.types.path;
      default = ./wallpapers/nixppuccin.png;
    };
    wallpapers = lib.mkOption {
      type = lib.types.path;
      default = ./wallpapers;
    };
  };
}
