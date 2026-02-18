{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.ui.fileManager;
in
{
  options.ui.fileManager = {
    enable = mkEnableOption "fileManager";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ unzip ];

    programs.thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin # Provides file context menus for archives
        thunar-volman # Automatic management of removable drives and media
      ];
    };

    services.gvfs.enable = true; # Mount, trash, and other functionalities
    services.tumbler.enable = true; # Thumbnail support for images
  };
}
