{ self, ... }: {
  flake.wrappers.niri =
    { pkgs, lib, ... }:
    let
      noctalia =
        cmd:
        [
          (lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia)
          "msg"
        ]
        ++ (lib.splitString " " cmd);
    in
    {
      settings.binds = {
        # Core Noctalia Bindings
        "Ctrl+Alt+Shift+Space".spawn = noctalia "panel-toggle launcher";
        "Mod+Ctrl+Alt+Shift+S".spawn = noctalia "panel-toggle control-center";
        "Mod+Ctrl+Alt+Shift+X".spawn = noctalia "panel-toggle session";
        "Mod+Ctrl+Alt+Shift+Comma".spawn = noctalia "settings-toggle";
        "Mod+Ctrl+Alt+Shift+N".spawn = noctalia "session lock";
        "Ctrl+Alt+Shift+N".spawn = noctalia "session lock-and-suspend";
        "Mod+Ctrl+Alt+Shift+B".spawn = noctalia "bar-toggle";

        # Media
        "XF86AudioPlay".spawn = noctalia "media toggle";
        "XF86AudioPrev".spawn = noctalia "media previous";
        "XF86AudioNext".spawn = noctalia "media next";

        # Brightness
        "XF86MonBrightnessUp".spawn = noctalia "brightness-up";
        "XF86MonBrightnessDown".spawn = noctalia "brightness-down";

        # Wallpaper
        "Mod+Ctrl+Alt+Shift+R".spawn = noctalia "wallpaper-random";
      };
    };
}
