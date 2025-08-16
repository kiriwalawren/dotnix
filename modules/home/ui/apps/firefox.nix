{
  inputs,
  lib,
  config,
  pkgs,
  system,
  ...
}:
with lib; let
  firefox-addons = inputs.firefox-addons.packages.${system};
  cfg = config.ui.apps.firefox;
in {
  options.ui.apps.firefox = {enable = mkEnableOption "firefox";};

  config = mkIf cfg.enable {
    programs.firefox = {
      enable = true;

      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        SearchBar = "unified";
      };

      profiles.default = {
        id = 0;
        name = "default";
        isDefault = true;

        settings = {
          "browser.search.defaultenginename" = "ddg";
          "browser.startup.page" = 3; # remember tabs
          "browser.tabs.inTitlebar" = 0; # start with tabs sidebar open
          "sidebar.verticalTabs" = true; # use vertical tabs

          # Privacy Settings
          "extensions.pocket.enabled" = false;
          "browser.topsites.contile.enabled" = false;
          "browser.newtabpage.pinned" = "";
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.system.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "signon.rememberSignons" = false;
        };

        extensions.packages = with firefox-addons; [
          bitwarden
          darkreader
          firefox-color
          stylus
          ublock-origin
          vimium
        ];

        search = {
          force = true;
          default = "ddg";
          order = ["ddg" "google"];
          engines = {
            "Nix Packages" = {
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "type";
                      value = "packages";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = ["@np" "@nixpkgs"];
            };
            "Nix Options" = {
              urls = [
                {
                  template = "https://search.nixos.org/options";
                  params = [
                    {
                      name = "type";
                      value = "packages";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = ["@no" "@nixopts"];
            };
            "NixOS Wiki" = {
              urls = [{template = "https://nixos.wiki/index.php?search={searchTerms}";}];
              iconUpdateUrl = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000; # every day
              definedAliases = ["@nw" "@nixwiki"];
            };
            "bing".metaData.hidden = true;
            "google".metaData.alias = "@g"; # builtin engines only support specifying one additional alias
          };
        };
      };
    };
  };
}
