{
  config,
  pkgs,
  lib,
  profileDir,
}:
let
  pkg = pkgs.catppuccin-userstyles.override {
    darkFlavor = config.catppuccin.flavor;
    accentColor = config.catppuccin.accent;
  };
  styles = builtins.fromJSON (builtins.readFile "${pkg}/styles.json");

  # A plain http(s) URL's authority (host[:port], no scheme/path) - matches
  # what Dark Reader itself stores in disabledFor (browser.storage.local key
  # "disabledFor", written via getURLHostOrProtocol()/`new URL(url).host`).
  hostFromUrl =
    url:
    let
      m = builtins.match "^[a-zA-Z][a-zA-Z0-9+.-]*://([^/]+).*" url;
    in
    if m == null then null else builtins.head m;

  hostsForSection =
    sec:
    (sec.domains or [ ])
    ++ (map hostFromUrl (sec.urlPrefixes or [ ]))
    ++ (map hostFromUrl (sec.urls or [ ]))
    # Dark Reader's own matcher accepts `/regex/`-delimited entries in
    # disabledFor too, using the same pattern engine - for the handful of
    # sites with only a regexp target (no plain domain), pass it through
    # rather than trying to guess a hostname out of the pattern.
    ++ (map (r: "/" + r + "/") (sec.regexps or [ ]));

  hosts = lib.unique (
    lib.filter (h: h != null) (lib.concatMap (s: lib.concatMap hostsForSection s.sections) styles)
  );

  hostsJson = builtins.toJSON hosts;
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
  # on every switch - the same mistake extensions.settings makes (see the
  # catppuccin-stylus wiring for why that's avoided here too). A stale
  # symlink left over from an extensions.settings-based approach is treated
  # the same as "no file yet".
  if [ -f "$dr_file" ] && [ ! -L "$dr_file" ]; then
    src="$dr_file"
  else
    src="$dr_file.empty"
    printf '{}' > "$src"
  fi

  tmp="$dr_file.tmp"
  ${pkgs.jq}/bin/jq \
    --argjson hosts '${hostsJson}' \
    --arg bg '${darkSchemeBackgroundColor}' \
    --arg fg '${darkSchemeTextColor}' \
    --arg sel '${selectionColor}' \
    '
      .disabledFor = ((.disabledFor // []) + $hosts | unique)
      | .previewNewDesign = true
      | .syncSettings = false
      | .theme = ((.theme // {}) + {
          darkSchemeBackgroundColor: $bg,
          darkSchemeTextColor: $fg,
          selectionColor: $sel,
          styleSystemControls: true
        })
    ' "$src" > "$tmp" && mv "$tmp" "$dr_file"
  rm -f "$dr_file.empty"
''
