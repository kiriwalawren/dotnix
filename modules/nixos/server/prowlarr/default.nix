{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  mkProwlarrIndexersService = import ./indexersService.nix {inherit lib pkgs;};

  # Define prowlarr-specific config options here
  extraConfigOptions = {
    indexers = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Name of the Prowlarr Indexer Schema";
          };
          apiKeyPath = mkOption {
            type = types.str;
            description = "Path to file containing the API key for the indexer";
          };
          appProfileId = mkOption {
            type = types.int;
            default = 1;
            description = "Application profile ID for the indexer (default: 1)";
          };
        };
      });
      default = [];
      description = ''
        List of indexers to configure in Prowlarr.
        Any additional attributes beyond name, apiKeyPath, and appProfileId
        will be applied as field values to the indexer schema.
      '';
    };
  };
in {
  imports = [(import ../arr-common/mkArrServiceModule.nix "prowlarr" extraConfigOptions {inherit config lib pkgs;})];

  config = {
    server.prowlarr = {
      usesDynamicUser = true;
      config = {
        apiVersion = lib.mkDefault "v1";
        hostConfig = {
          port = lib.mkDefault 9696;
          branch = lib.mkDefault "master";
        };

        indexers = mkIf (config.server.enable && config.server.prowlarr.enable) [
          {
            name = "DrunkenSlug";
            apiKeyPath = config.sops.secrets."indexer-api-keys/DrunkenSlug".path;
          }
          {
            name = "NZBFinder";
            apiKeyPath = config.sops.secrets."indexer-api-keys/NZBFinder".path;
          }
        ];
      };
    };

    sops.secrets = mkIf (config.server.enable && config.server.prowlarr.enable) {
      "indexer-api-keys/DrunkenSlug" = {mode = "0440";};
      "indexer-api-keys/NZBFinder" = {mode = "0440";};
    };

    systemd.services."prowlarr-indexers" = mkIf (config.server.enable && config.server.prowlarr.enable) (
      mkProwlarrIndexersService "prowlarr" config.server.prowlarr.config
    );
  };
}
