{ pkgs, ... }: {
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

    github-issues = {
      urls = [ { template = "https://github.com/search?type=issues&q={searchTerms}"; } ];
      definedAliases = [ "@ghi" ];
    };

    bing.metaData.hidden = true;
  };
}
