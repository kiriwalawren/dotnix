{
  pkgs,
  lib,
  config,
  theme,
  ...
}:
with lib;
let
  cfg = config.ui.nixos.hyprland.hyprpaper;

  wallpapers = filesystem.listFilesRecursive theme.wallpapers;

  wallpaperBashArray = "(\"${
    strings.concatStrings (strings.intersperse "\" \"" (map (wallpaper: "${wallpaper}") wallpapers))
  }\")";
  wallpaperRandomizer = pkgs.writeShellScriptBin "wallpaperRandomizer" ''
    wallpapers=${wallpaperBashArray}
    rand=$[$RANDOM % ''${#wallpapers[@]}]
    wallpaper=''${wallpapers[$rand]}

    monitor=(`hyprctl monitors | grep Monitor | awk '{print $2}'`)
    for m in ''${monitor[@]}; do
      hyprctl hyprpaper wallpaper "$m,$wallpaper"
    done
  '';
in
{
  options.ui.nixos.hyprland.hyprpaper = {
    enable = mkEnableOption "hyprpaper";
  };

  config = mkIf cfg.enable {
    home.packages = [ wallpaperRandomizer ];

    services.hyprpaper = {
      enable = true;

      settings = {
        ipc = "on";
        splash = false;
        splash_offset = 2;
      };
    };

    systemd.user = {
      services.wallpaperRandomizer = {
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };

        Unit = {
          Description = "Set random desktop background using hyprpaper";
          After = [
            "graphical-session.target"
            "hyprpaper.service"
          ];
          Requires = [ "hyprpaper.service" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${wallpaperRandomizer}/bin/wallpaperRandomizer";
          IOSchedulingClass = "idle";
        };
      };

      timers.wallpaperRandomizer = {
        Unit = {
          Description = "Set random desktop background using hyprpaper on an interval";
        };

        Timer = {
          OnUnitActiveSec = "1h";
        };

        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    };
  };
}
