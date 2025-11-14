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
        apiKeyPath = config.sops.secrets."prowlarr/api_key".path;
        hostConfig.passwordPath = config.sops.secrets."prowlarr/password".path;
        indexers = [
          {
            name = "DrunkenSlug";
            apiKeyPath = config.sops.secrets."indexer-api-keys/DrunkenSlug".path;
          }
          {
            name = "NZBFinder";
            apiKeyPath = config.sops.secrets."indexer-api-keys/NZBFinder".path;
          }
          {
            name = "NzbPlanet";
            apiKeyPath = config.sops.secrets."indexer-api-keys/NzbPlanet".path;
          }
        ];
      };
    };
  };
}
