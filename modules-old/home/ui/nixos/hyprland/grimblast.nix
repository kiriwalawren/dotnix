{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.ui.nixos.hyprland.grimblast;
in
{
  options.ui.nixos.hyprland.grimblast = {
    enable = mkEnableOption "grimblast";
  };

  config = mkIf cfg.enable {
    home = {
      packages = [
        pkgs.grimblast
        pkgs.satty
      ];

      # small wrapper to accept either a filename arg or stdin
      file.".local/bin/annotate-with-satty" = {
        # ensure executable
        executable = true;
        text = ''
          #!/usr/bin/env bash
          set -euo pipefail

          # common satty flags
          SATTY_FLAGS=(
            --fullscreen
            --copy-command "${pkgs.wl-clipboard}/bin/wl-copy"
            --early-exit
            --init-tool line
            --actions-on-escape "save-to-clipboard"
            --actions-on-enter "save-to-clipboard,save-to-file"
          )

          if [ -n "$1" ] && [ -f "$1" ]; then
            # If called with an existing file, open it directly
            ${pkgs.satty}/bin/satty --filename "$1" --output-filename "$1" "''${SATTY_FLAGS[@]}"
          else
            # Otherwise read stdin into a temp file and open it
            tmp=$(mktemp --suffix=.png)
            cat - > "$tmp"
            ${pkgs.satty}/bin/satty --filename "$tmp" --output-filename "$tmp" "''${SATTY_FLAGS[@]}"
          fi
        '';
      };

      # point grimblast at the wrapper
      sessionVariables = {
        GRIMBLAST_EDITOR = "$HOME/.local/bin/annotate-with-satty";
      };
    };

    wayland.windowManager.hyprland.settings = {
      env = [
        "GRIMBLAST_EDITOR,$HOME/.local/bin/annotate-with-satty"
      ];

      bind = [
        "SUPER,C,exec,grimblast copy area"
        "SUPER,E,exec,grimblast edit area"
      ];
    };
  };
}
