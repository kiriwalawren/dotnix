REPO="/home/walawren/gitrepos/dotnix"
SETTINGS_FILE="$HOME/.config/noctalia/settings.json"
KITTY_THEME_FILE="$HOME/.config/kitty/themes/noctalia.conf"

if [ ! -f "$SETTINGS_FILE" ] || [ ! -f "$KITTY_THEME_FILE" ]; then
  exit 0
fi

SCHEME_NAME=$(jq -r '.colorSchemes.predefinedScheme // "Catppuccin"' "$SETTINGS_FILE")

field() {
  awk -v key="$1" '$1 == key { print $2 }' "$KITTY_THEME_FILE" | sed 's/^#//'
}

BACKGROUND=$(field background)
FOREGROUND=$(field foreground)
SELECTION_BG=$(field selection_background)
PRIMARY=$(field active_border_color)
SECONDARY=$(field inactive_border_color)
SURFACE_VARIANT=$(field inactive_tab_background)
ON_SURFACE_VARIANT=$(field inactive_tab_foreground)
COLOR1=$(field color1)
COLOR2=$(field color2)
COLOR3=$(field color3)
COLOR6=$(field color6)
COLOR8=$(field color8)

if command -v tmux >/dev/null 2>&1; then
  TMUX_THEME="$HOME/.config/tmux/noctalia.tmux"
  mkdir -p "$(dirname "$TMUX_THEME")"
  cat >"$TMUX_THEME" <<EOF
set -g status-style "bg=#$BACKGROUND,fg=#$FOREGROUND"
set -g message-style "bg=#$BACKGROUND,fg=#$FOREGROUND"
set -g pane-active-border-style "fg=#$PRIMARY"
set -g pane-border-style "fg=#$SURFACE_VARIANT"
set -g status-left-style "fg=#$PRIMARY,bold"
set -g status-right-style "fg=#$ON_SURFACE_VARIANT"
set -g window-status-current-style "fg=#$PRIMARY,bold"
EOF
  if tmux info >/dev/null 2>&1; then
    tmux source-file "$TMUX_THEME" >/dev/null 2>&1 || true
  fi
fi

if command -v fish >/dev/null 2>&1; then
  fish -c "
    set -U fish_color_command '$PRIMARY'
    set -U fish_color_keyword '$SECONDARY'
    set -U fish_color_error '$COLOR1'
    set -U fish_color_param '$FOREGROUND'
    set -U fish_color_cwd '$COLOR6'
    set -U fish_color_host '$SECONDARY'
    set -U fish_color_host_remote '$PRIMARY'
  " >/dev/null 2>&1 || true
fi

NVIM_STATE="$HOME/.config/nvim/current-scheme.json"
mkdir -p "$(dirname "$NVIM_STATE")"

NVIM_NAME=""
case "$SCHEME_NAME" in
  Ayu) NVIM_NAME="ayu" ;;
  Catppuccin) NVIM_NAME="catppuccin" ;;
  Dracula) NVIM_NAME="dracula" ;;
  Eldritch) NVIM_NAME="eldritch" ;;
  Gruvbox) NVIM_NAME="gruvbox" ;;
  Kanagawa) NVIM_NAME="kanagawa" ;;
  Nord) NVIM_NAME="nord" ;;
  Rosepine) NVIM_NAME="rose-pine" ;;
  Tokyo-Night) NVIM_NAME="tokyonight" ;;
esac

if [ -n "$NVIM_NAME" ]; then
  jq -n --arg name "$NVIM_NAME" '{mode: "curated", name: $name}' >"$NVIM_STATE"
else
  jq -n \
    --arg base00 "#$BACKGROUND" --arg base01 "#$SURFACE_VARIANT" --arg base02 "#$SURFACE_VARIANT" \
    --arg base03 "#$ON_SURFACE_VARIANT" --arg base04 "#$ON_SURFACE_VARIANT" --arg base05 "#$FOREGROUND" \
    --arg base06 "#$FOREGROUND" --arg base07 "#$FOREGROUND" --arg base08 "#$COLOR1" \
    --arg base09 "#$COLOR3" --arg base0A "#$COLOR3" --arg base0B "#$COLOR2" \
    --arg base0C "#$COLOR6" --arg base0D "#$PRIMARY" --arg base0E "#$SECONDARY" --arg base0F "#$COLOR8" \
    '{mode: "generic", colors: {base00:$base00,base01:$base01,base02:$base02,base03:$base03,base04:$base04,base05:$base05,base06:$base06,base07:$base07,base08:$base08,base09:$base09,base0A:$base0A,base0B:$base0B,base0C:$base0C,base0D:$base0D,base0E:$base0E,base0F:$base0F}}' \
    >"$NVIM_STATE"
fi

for DR_FILE in \
  "$HOME/.config/mozilla/firefox/walawren/browser-extension-data/addon@darkreader.org/storage.js" \
  "$HOME/.config/zen/default/browser-extension-data/addon@darkreader.org/storage.js"; do
  if [ -f "$DR_FILE" ]; then
    DR_TMP="$DR_FILE.tmp"
    if jq --arg bg "#$BACKGROUND" --arg fg "#$FOREGROUND" --arg sel "#$SELECTION_BG" '
        .detectDarkTheme = false
        | .theme = ((.theme // {}) + {
          darkSchemeBackgroundColor: $bg,
          darkSchemeTextColor: $fg,
          selectionColor: $sel,
          styleSystemControls: true
        })
      ' "$DR_FILE" >"$DR_TMP" 2>/dev/null; then
      mv "$DR_TMP" "$DR_FILE"
    else
      rm -f "$DR_TMP"
    fi
  fi
done

SCHEME_OPTION_FILE="$REPO/modules/system/theme/scheme-option.nix"
if [ -f "$SCHEME_OPTION_FILE" ]; then
  sed -i "s/default = \"[^\"]*\";/default = \"$SCHEME_NAME\";/" "$SCHEME_OPTION_FILE" || true
fi

exit 0
