{ self, ... }: {
  flake.wrappers.niri =
    { pkgs, lib, ... }:
    let
      bind = import ../niri/_bind.nix;
      noctalia =
        cmd:
        [
          (lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia)
          "msg"
        ]
        ++ (lib.splitString " " cmd);

      # Toggles caffeine and notifies its new state; noctalia's `status` doesn't report caffeine,
      # but while on it holds a logind idle inhibitor named "Caffeine"
      caffeine-toggle = pkgs.writeShellApplication {
        name = "caffeine-toggle";
        runtimeInputs = [
          self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia
          self.packages.${pkgs.stdenv.hostPlatform.system}.notify-replace
          pkgs.jq
          pkgs.systemd # busctl
        ];
        text = ''
          noctalia msg caffeine-toggle >/dev/null

          if busctl call --json=short org.freedesktop.login1 /org/freedesktop/login1 \
            org.freedesktop.login1.Manager ListInhibitors |
            jq -e 'any(.data[0][]; .[0] == "idle" and .[1] == "noctalia" and .[2] == "Caffeine")' >/dev/null; then
            state=on
          else
            state=off
          fi

          notify-replace caffeine-toggle --app-name=noctalia "Caffeine" "$state"
        '';
      };
    in
    {
      settings.binds = {
        # Core Noctalia Bindings
        "Ctrl+Alt+Shift+Space" = bind "App launcher" { spawn = noctalia "panel-toggle launcher"; };
        "Mod+Space" = bind "App launcher" { spawn = noctalia "panel-toggle launcher"; };
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
