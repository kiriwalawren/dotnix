{
  flake.wrappers.noctalia = { lib, pkgs, ... }: {
    env.TERMINAL = lib.getExe pkgs.kitty;

    settings.shell = {
      clipboard_enabled = true;
      clipboard_auto_paste = "off";
      clipboard_image_action_command = "${lib.getExe pkgs.satty} -f -";

      panel = {
        launcher_placement = "floating";
        launcher_position = "center";
      };

      launcher = {
        pinned = [ ];
        sort_by_usage = true;
        app_grid = false;
        categories = true;
        compact = false;
      };
    };
  };
}
