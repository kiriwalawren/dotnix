{ inputs, ... }:
{
  flake.modules.homeManager.gui = {
    imports = [ inputs.zen-browser.homeModules.default ];

    programs.zen-browser = {
      enable = true;
      # setAsDefaultBrowser = true;

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
      };
    };
  };
}
