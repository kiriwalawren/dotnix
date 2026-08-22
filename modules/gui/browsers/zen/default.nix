{ inputs, ... }:
{
  flake.modules.homeManager.gui = { pkgs, ... }: {
    imports = [ inputs.zen-browser.homeModules.default ];

    programs.zen-browser = {
      enable = true;
      setAsDefaultBrowser = true;

      profiles.default = {
        settings = {
          # Set to 0 when this is fixed: https://github.com/zen-browser/desktop/discussions/11053#discussioncomment-16941377
          "zen.theme.content-element-separation" = 1;

          "browser.aboutConfig.showWarning" = false;
          "browser.startup.page" = 3; # remember tabs

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
        };

        search = {
          force = true;
          default = "ddg";
          engines = {
            nix-packages = {
              urls = [ { template = "https://search.nixos.org/packages?type=packages&query={searchTerms}"; } ];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };

            nix-options = {
              urls = [ { template = "https://search.nixos.org/options?type=packages&query={searchTerms}"; } ];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@no" ];
            };

            nixpkgs-tracker = {
              urls = [ { template = "https://nixpk.gs/pr-tracker.html?pr={searchTerms}"; } ];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@nt" ];
            };

            nixos-wiki = {
              urls = [ { template = "https://nixos.wiki/index.php?search={searchTerms}"; } ];
              iconUpdateUrl = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000; # every day
              definedAliases = [ "@nw" ];
            };

            youtube = {
              urls = [ { template = "https://youtube.com/results?search_query={searchTerms}"; } ];
              definedAliases = [ "@yt" ];
            };

            github-code = {
              urls = [ { template = "https://github.com/search?type=code&q={searchTerms}"; } ];
              definedAliases = [ "@ghc" ];
            };

            github-repos = {
              urls = [ { template = "https://github.com/search?type=repositories&q={searchTerms}"; } ];
              definedAliases = [ "@ghr" ];
            };

            bing.metaData.hidden = true;
          };
        };
      };
    };
  };
}
