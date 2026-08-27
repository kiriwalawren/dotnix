{
  config,
  pkgs,
  lib,
  profileDir,
}:
let
  darkreaderStorage = "${profileDir}/browser-extension-data/addon@darkreader.org/storage.js";

  darkSchemeBackgroundColor = "#${config.catppuccin.colors.base}";
  darkSchemeTextColor = "#${config.catppuccin.colors.text}";
  selectionColor = "#${config.catppuccin.colors.surface2}";
in
lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  dr_file='${darkreaderStorage}'
  mkdir -p "$(dirname "$dr_file")"

  # Merge, don't overwrite: Dark Reader keeps its own runtime state (news
  # dismissals, per-site enabledFor overrides, install metadata, ...) in this
  # same file, and a full home.file-style overwrite would discard all of it
  # on every switch.
  if [ -f "$dr_file" ] && [ ! -L "$dr_file" ]; then
    src="$dr_file"
  else
    src="$dr_file.empty"
    printf '{}' > "$src"
  fi

  tmp="$dr_file.tmp"
  ${pkgs.jq}/bin/jq \
    --arg bg '${darkSchemeBackgroundColor}' \
    --arg fg '${darkSchemeTextColor}' \
    --arg sel '${selectionColor}' \
    '
      .previewNewDesign = true
      | .syncSettings = false
      | .detectDarkTheme = false
      | .theme = ((.theme // {}) + {
          darkSchemeBackgroundColor: $bg,
          darkSchemeTextColor: $fg,
          selectionColor: $sel,
          styleSystemControls: true
        })
    ' "$src" > "$tmp" && mv "$tmp" "$dr_file"
  rm -f "$dr_file.empty"
''
