# A niri bind with a `hotkey-overlay-title`, e.g.
#   "Mod+Ctrl+Alt+Shift+Q" = bind "Close window" { spawn = [ ... ]; };
# The title shows in niri's hotkey overlay and in the Noctalia shortcut
# legend (modules/gui/desktop/noctalia/keyboard-overlay.nix), which reads
# only `props` so it never forces the bind's action.
title: action: _: {
  props.hotkey-overlay-title = title;
  content = action;
}
