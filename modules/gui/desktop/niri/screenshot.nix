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
            set -eo pipefail
            tmp=$(mktemp --suffix=.png)
            ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp -d)" "$tmp"
            systemd-run --user --scope \
              ${pkgs.satty}/bin/satty \
                --filename "$tmp" \
                --output-filename "$tmp" \
                --fullscreen \
                --copy-command "${pkgs.wl-clipboard}/bin/wl-copy" \
                --early-exit \
                --init-tool line \
                --actions-on-escape "save-to-clipboard" \
                --actions-on-enter "save-to-clipboard,save-to-file"
            rm -f "$tmp"
          '';
        };
      };

      programs.niri.settings.binds = {
        "Mod+C".action.spawn = [ "${config.home.homeDirectory}/.local/bin/screenshot-copy" ];
        "Mod+E".action.spawn = [ "${config.home.homeDirectory}/.local/bin/screenshot-edit" ];
      };
    };
}
