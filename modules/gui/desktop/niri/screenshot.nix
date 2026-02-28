{
  flake.modules.homeManager.niri =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      home = {
        packages = [
          pkgs.grim
          pkgs.slurp
          pkgs.satty
          pkgs.wl-clipboard
        ];

        # small wrapper to accept either a filename arg or stdin
        file.".local/bin/annotate-with-satty" = {
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
              ${pkgs.satty}/bin/satty --filename "$1" --output-filename "$1" "''${SATTY_FLAGS[@]}"
            else
              tmp=$(mktemp --suffix=.png)
              cat - > "$tmp"
              ${pkgs.satty}/bin/satty --filename "$tmp" --output-filename "$tmp" "''${SATTY_FLAGS[@]}"
            fi
          '';
        };

        # copy area to clipboard
        file.".local/bin/screenshot-copy" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            set -euo pipefail
            ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.wl-clipboard}/bin/wl-copy
          '';
        };

        # capture area and open in satty for annotation
        file.".local/bin/screenshot-edit" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            set -euo pipefail
            ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | $HOME/.local/bin/annotate-with-satty
          '';
        };
      };

      programs.niri.settings.binds = {
        "Mod+C".action.spawn = [ "${config.home.homeDirectory}/.local/bin/screenshot-copy" ];
        "Mod+E".action.spawn = [ "${config.home.homeDirectory}/.local/bin/screenshot-edit" ];
      };
    };
}
