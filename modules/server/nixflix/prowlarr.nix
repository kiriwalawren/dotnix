{
  flake.modules.nixos.homelab =
    { config, ... }:
    {
      sops.secrets = {
        "indexer-api-keys/DrunkenSlug" = { };
        "indexer-api-keys/NZBFinder" = { };
        "indexer-api-keys/NzbPlanet" = { };
        "indexer-api-keys/NZBgeek" = { };
        "prowlarr/api_key" = { };
        "prowlarr/password" = { };
      };

      nixflix.prowlarr = {
        enable = true;
        subdomain = "indexers";

        config = {
          apiKey._secret = config.sops.secrets."prowlarr/api_key".path;
          hostConfig.password._secret = config.sops.secrets."prowlarr/password".path;
          indexers = [
            # NZB Indexers
            {
              enable = true;
              name = "DrunkenSlug";
              apiKey._secret = config.sops.secrets."indexer-api-keys/DrunkenSlug".path;
            }
            {
              enable = true;
              name = "NZBFinder";
              apiKey._secret = config.sops.secrets."indexer-api-keys/NZBFinder".path;
            }
            {
              enable = true;
              name = "NzbPlanet";
              apiKey._secret = config.sops.secrets."indexer-api-keys/NzbPlanet".path;
            }
            {
              enable = true;
              name = "NZBgeek";
              apiKey._secret = config.sops.secrets."indexer-api-keys/NZBgeek".path;
            }

            # Torrent indexers
            {
              enable = true;
              name = "Nyaa.si";
              baseUrl = "https://nyaa.si/";
              radarr_compatibility = true;
              sonarr_compatibility = true;
            }
            {
              enable = true;
              name = "YTS";
              baseUrl = "https://yts.bz/";
            }
            {
              enable = false;
              name = "The Pirate Bay";
              baseUrl = "https://thepiratebay.org/";
            }
            {
              enable = false;
              name = "LimeTorrents";
              baseUrl = "https://www.limetorrents.fun/";
            }
            {
              enable = false;
              name = "TorrentDownload";
              baseUrl = "https://www.torrentdownload.info/";
            }
          ];
        };
      };
    };
}
