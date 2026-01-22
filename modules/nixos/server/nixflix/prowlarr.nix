{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.server.nixflix.enable {
    sops.secrets = {
      "indexer-api-keys/DrunkenSlug" = {};
      "indexer-api-keys/NZBFinder" = {};
      "indexer-api-keys/NzbPlanet" = {};
      "prowlarr/api_key" = {};
      "prowlarr/password" = {};
    };

    nixflix.prowlarr = {
      enable = true;
      config = {
        apiKey = {_secret = config.sops.secrets."prowlarr/api_key".path;};
        hostConfig.password = {_secret = config.sops.secrets."prowlarr/password".path;};
        indexers = [
          {
            name = "DrunkenSlug";
            apiKey = {_secret = config.sops.secrets."indexer-api-keys/DrunkenSlug".path;};
          }
          {
            name = "NZBFinder";
            apiKey = {_secret = config.sops.secrets."indexer-api-keys/NZBFinder".path;};
          }
          {
            name = "NzbPlanet";
            apiKey = {_secret = config.sops.secrets."indexer-api-keys/NzbPlanet".path;};
          }
        ];
      };
    };
  };
}
