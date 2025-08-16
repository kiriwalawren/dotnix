{lib, ...}: {
  meta.doc = lib.mdDoc ''
    Root NixOS configuration module that imports all system components.

    Aggregates system configuration, home manager integration, and UI modules
    for comprehensive NixOS system setup.
  '';

  imports = [
    ./home.nix
    ./system
    ./ui
  ];
}
