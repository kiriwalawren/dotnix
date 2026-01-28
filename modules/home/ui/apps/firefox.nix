{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
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
          "browser.tabs.inTitlebar" = 0;

          # Font configuration
          "browser.display.use_document_fonts" = 0; # prevent sites from overriding fonts

          # Sidebar configuration
          "sidebar.verticalTabs" = true; # enable vertical tabs
          "sidebar.revamp" = true; # use new sidebar
          "sidebar.backupState" = builtins.toJSON {
            command = "";
            panelOpen = false;
            launcherWidth = 0;
            launcherExpanded = false;
            launcherVisible = false; # sidebar collapsed by default
          };
          # Disable "Hide tabs and sidebar" auto-hide behavior
          "sidebar.visibility.hide-sidebar-and-tabs" = false;

          # Privacy Settings
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.system.showSponsored" = false;
          "browser.newtabpage.pinned" = "";
          "browser.topsites.contile.enabled" = false;
          "extensions.pocket.enabled" = false;
          "signon.rememberSignons" = false;

          # Disable autofill for addresses and payment methods
          "extensions.formautofill.addresses.enabled" = false;
          "extensions.formautofill.creditCards.enabled" = false;

          # Enable "Tell websites not to sell or share my data"
          "privacy.globalprivacycontrol.enabled" = true;

          # Toolbar layout configuration
          "browser.uiCustomization.state" = builtins.toJSON {
            placements = {
              widget-overflow-fixed-list = [];
              unified-extensions-area = [
                "_d7742d87-e61d-4b78-b8a1-b469842139fa_-browser-action"
                "ublock0_raymondhill_net-browser-action"
                "addon_darkreader_org-browser-action"
                "firefoxcolor_mozilla_com-browser-action"
                "_7a7a4a92-a2a0-41d1-9fd7-1e92480d612d_-browser-action"
              ];
              nav-bar = [
                "back-button"
                "forward-button"
                "stop-reload-button"
                "urlbar-container"
                "vertical-spacer"
                "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
                "unified-extensions-button"
                "sidebar-button"
              ];
              toolbar-menubar = ["menubar-items"];
              TabsToolbar = [];
              vertical-tabs = ["tabbrowser-tabs"];
              PersonalToolbar = ["import-button" "personal-bookmarks"];
            };
            seen = [
              "developer-button"
              "screenshot-button"
              "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
              "addon_darkreader_org-browser-action"
              "firefoxcolor_mozilla_com-browser-action"
              "_7a7a4a92-a2a0-41d1-9fd7-1e92480d612d_-browser-action"
              "ublock0_raymondhill_net-browser-action"
              "_d7742d87-e61d-4b78-b8a1-b469842139fa_-browser-action"
            ];
            dirtyAreaCache = [
              "nav-bar"
              "TabsToolbar"
              "vertical-tabs"
              "PersonalToolbar"
              "unified-extensions-area"
              "toolbar-menubar"
            ];
            currentVersion = 23;
            newElementCount = 4;
          };
        };

        extensions.packages = with pkgs.firefox-addons; [
          bitwarden
          darkreader
          firefox-color
          hover-zoom-plus
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
