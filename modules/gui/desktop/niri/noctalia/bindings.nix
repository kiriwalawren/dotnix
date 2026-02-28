{
  flake.modules.homeManager.niri =
    { pkgs, ... }:
    let
      noctalia =
        cmd:
        [
          "noctalia-shell"
          "ipc"
          "call"
        ]
        ++ (pkgs.lib.splitString " " cmd);
    in
    {
      programs.niri.settings = {
        binds = {
          # Core Noctalia Bindings
          "Mod+Space".action.spawn = noctalia "launcher toggle";
          "Mod+S".action.spawn = noctalia "controlCenter toggle";
          "Mod+X".action.spawn = noctalia "sessionMenu toggle";
          "Mod+Comma".action.spawn = noctalia "settings toggle";
          "Mod+N".action.spawn = noctalia "lockScreen lock";
          "Mod+Shift+N".action.spawn = noctalia "sessionMenu lockAndSuspend";
          "Mod+B".action.spawn = noctalia "bar toggle";

          # Audio
          "XF86AudioRaiseVolume".action.spawn = noctalia "volume increase";
          "XF86AudioLowerVolume".action.spawn = noctalia "volume decrease";
          "XF86AudioMute".action.spawn = noctalia "volume muteOutput";
          "CTRL+Space".action.spawn = noctalia "volume muteInput";

          # Media
          "XF86AudioPlay".action.spawn = noctalia "media playPause";
          "XF86AudioPrev".action.spawn = noctalia "media previous";
          "XF86AudioNext".action.spawn = noctalia "media next";

          # Brightness
          "XF86MonBrightnessUp".action.spawn = noctalia "brightness increase";
          "XF86MonBrightnessDown".action.spawn = noctalia "brightness decrease";
        };
      };
    };
}
