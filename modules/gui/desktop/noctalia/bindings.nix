{ self, ... }: {
  flake.wrappers.niri =
    { pkgs, lib, ... }:
    let
      bind = import ../niri/_bind.nix;
      noctaliaExe = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia;
      noctalia =
        cmd:
        [
          noctaliaExe
          "msg"
        ]
        ++ (lib.splitString " " cmd);

      # `caffeine-toggle` only replies "ok" and `msg status` has no caffeine field, so
      # read the new state from the logind idle inhibitor Noctalia holds while it is on.
      caffeine-toggle = pkgs.writeShellScriptBin "caffeine-toggle" ''
        set -euo pipefail
        ${noctaliaExe} msg caffeine-toggle > /dev/null
        active="$(${pkgs.systemd}/bin/busctl --json=short call \
          org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager \
          ListInhibitors \
          | ${lib.getExe pkgs.jq} '.data[0] | any(.[0] == "idle" and .[1] == "noctalia" and .[2] == "Caffeine")')"
        if [ "$active" = true ]; then state=Enabled; else state=Disabled; fi
        ${noctaliaExe} msg notification-show Caffeine "$state"
      '';
    in
    {
      settings.binds = {
        # Core Noctalia Bindings
        "Ctrl+Alt+Shift+Space" = bind "App launcher" { spawn = noctalia "panel-toggle launcher"; };
        "Mod+Ctrl+Alt+Shift+S" = bind "Control center" { spawn = noctalia "panel-toggle control-center"; };
        "Mod+Ctrl+Alt+Shift+X" = bind "Session menu" { spawn = noctalia "panel-toggle session"; };
        "Mod+Ctrl+Alt+Shift+Comma" = bind "Noctalia settings" { spawn = noctalia "settings-toggle"; };
        "Mod+Ctrl+Alt+Shift+B" = bind "Toggle bar" { spawn = noctalia "bar-toggle"; };
        "Ctrl+Alt+Shift+C" = bind "Toggle caffeine" { spawn = [ (lib.getExe caffeine-toggle) ]; };

        # Media
        "XF86AudioPlay".spawn = noctalia "media toggle";
        "XF86AudioPrev".spawn = noctalia "media previous";
        "XF86AudioNext".spawn = noctalia "media next";

        # Brightness
        "XF86MonBrightnessUp".spawn = noctalia "brightness-up";
        "XF86MonBrightnessDown".spawn = noctalia "brightness-down";

        # Wallpaper
        "Mod+Ctrl+Alt+Shift+R" = bind "Random wallpaper" { spawn = noctalia "wallpaper-random"; };
      };
    };
}
