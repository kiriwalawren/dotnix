{
  flake.wrappers.niri =
    {
      pkgs,
      lib,
      ...
    }:
    let
      screenshot-copy = pkgs.writeShellScriptBin "screenshot-copy" ''
        set -euo pipefail
        ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.wl-clipboard}/bin/wl-copy
      '';

      screenshot-edit = pkgs.writeShellScriptBin "screenshot-edit" ''
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
    in
    {
      settings.binds = {
        "Mod+C".spawn = [ (lib.getExe screenshot-copy) ];
        "Mod+E".spawn = [ (lib.getExe screenshot-edit) ];
      };
    };
}
