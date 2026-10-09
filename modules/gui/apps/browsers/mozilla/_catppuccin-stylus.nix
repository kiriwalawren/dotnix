{
  config,
  pkgs,
  lib,
}:
let
  pkg = pkgs.catppuccin-userstyles.override {
    darkFlavor = config.catppuccin.flavor;
    accentColor = config.catppuccin.accent;
  };
  styles = builtins.fromJSON (builtins.readFile "${pkg}/styles.json");
in
{
  dbInChromeStorage = true;
}
// (lib.listToAttrs (lib.imap1 (i: s: lib.nameValuePair "style-${toString i}" s) styles))
