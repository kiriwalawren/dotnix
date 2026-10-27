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
        "Mod+Space".spawn = noctalia "panel-toggle launcher";
        "Mod+S".spawn = noctalia "panel-toggle control-center";
        "Mod+X".spawn = noctalia "panel-toggle session";
        "Mod+Comma".spawn = noctalia "settings-toggle";
        "Mod+N".spawn = noctalia "session lock";
        "Mod+Shift+N".spawn = noctalia "session lock-and-suspend";
        "Mod+B".spawn = noctalia "bar-toggle";

        # Media
        "XF86AudioPlay".spawn = noctalia "media toggle";
        "XF86AudioPrev".spawn = noctalia "media previous";
        "XF86AudioNext".spawn = noctalia "media next";

        # Brightness
        "XF86MonBrightnessUp".spawn = noctalia "brightness-up";
        "XF86MonBrightnessDown".spawn = noctalia "brightness-down";

        # Wallpaper
        "Mod+R".spawn = noctalia "wallpaper-random";
      };
    };
}
