{ self, ... }:
{
  flake.wrappers.niri =
    { pkgs, lib, ... }:
    let
      noctalia =
        cmd:
        [
          (lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia-shell)
          "ipc"
          "call"
        ]
        ++ (lib.splitString " " cmd);
    in
    {
      settings.binds = {
        # Core Noctalia Bindings
        "Mod+Space".spawn = noctalia "launcher toggle";
        "Mod+S".spawn = noctalia "controlCenter toggle";
        "Mod+X".spawn = noctalia "sessionMenu toggle";
        "Mod+Comma".spawn = noctalia "settings toggle";
        "Mod+N".spawn = noctalia "lockScreen lock";
        "Mod+Shift+N".spawn = noctalia "sessionMenu lockAndSuspend";
        "Mod+B".spawn = noctalia "bar toggle";

        # Media
        "XF86AudioPlay".spawn = noctalia "media playPause";
        "XF86AudioPrev".spawn = noctalia "media previous";
        "XF86AudioNext".spawn = noctalia "media next";

        # Brightness
        "XF86MonBrightnessUp".spawn = noctalia "brightness increase";
        "XF86MonBrightnessDown".spawn = noctalia "brightness decrease";

        # Wallpaper
        "Mod+R".spawn = noctalia "wallpaper random";
      };
    };

  # TODO: bindings for hyperland should be replicated/moved here
}
