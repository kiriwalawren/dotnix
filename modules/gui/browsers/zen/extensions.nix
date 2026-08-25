{
  flake.modules.homeManager.gui =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.zen-browser = {
        profiles.default = {
          extensions.force = true;
          extensions.settings."{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}".settings =
            import ../_catppuccin-stylus.nix
              { inherit config pkgs lib; };
        };
        policies.ExtensionSettings =
          let
            mkPluginUrl = id: "https://addons.mozilla.org/firefox/downloads/latest/${id}/latest.xpi";
            mkExtensionEntry =
              {
                id,
                pinned ? false,
                private_browsing ? false,
              }:
              let
                base = {
                  inherit private_browsing;
                  install_url = mkPluginUrl id;
                  installation_mode = "force_installed";
                };
              in
              if pinned then base // { default_area = "navbar"; } else base;

            mkExtensionSettings = builtins.mapAttrs (
              _: entry: if builtins.isAttrs entry then entry else mkExtensionEntry { id = entry; }
            );
          in
          mkExtensionSettings {
            "uBlock0@raymondhill.net" = mkExtensionEntry {
              id = "ublock-origin";
              private_browsing = true;
            };
            "{446900e4-71c2-419f-a6a7-df9c091e268b}" = mkExtensionEntry {
              id = "bitwarden-password-manager";
              pinned = true;
              private_browsing = true;
            };
            "addon@darkreader.org" = mkExtensionEntry {
              id = "darkreader";
            };
            "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}" = mkExtensionEntry {
              id = "styl-us";
            };
            "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = mkExtensionEntry {
              id = "vimium-ff";
            };
          };
      };
    };
}
