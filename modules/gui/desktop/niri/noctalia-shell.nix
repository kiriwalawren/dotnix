{ inputs, ... }:
{
  flake.modules.nixos.niri = {
    services.upower.enable = true;
  };

  flake.modules.homeManager.gui = {
    imports = [ inputs.noctalia.homeModules.default ];
  };

  flake.modules.homeManager.niri =
    { pkgs, ... }:
    {
      programs.niri.settings = {
        debug.honor-xdg-activation-with-invalid-serial = [ ];
        spawn-at-startup = [
          {
            command = [ "noctalia-shell" ];
          }
        ];

        binds =
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
            # Core Noctalia Bindings
            "Mod+Space".action.spawn = noctalia "launcher toggle";
            "Mod+S".action.spawn = noctalia "controlCenter toggle";
            "Mod+Comma".action.spawn = noctalia "settings toggle";
            "Mod+N".action.spawn = noctalia "lockScreen lock";
            "Mod+Shift+N".action.spawn = noctalia "sessionMenu lockAndSuspend";

            # Audio
            "XF86AudioRaiseVolume".action.spawn = noctalia "volume increase";
            "XF86AudioLowerVolume".action.spawn = noctalia "volume decrease";
            "XF86AudioMute".action.spawn = noctalia "volume muteOutput";

            # Brightness
            "XF86MonBrightnessUp".action.spawn = noctalia "brightness increase";
            "XF86MonBrightnessDown".action.spawn = noctalia "brightness decrease";
          };
      };

      programs.noctalia-shell = {
        enable = true;
        settings = {
          colorSchemes.predefinedScheme = "Catppuccin-Lavender";
        };
      };
    };
}
