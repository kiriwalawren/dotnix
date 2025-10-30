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
            description = "API key for the indexer";
          };
        };
      });
      default = [];
      description = "List of indexers to configure in Prowlarr";
    };
  };
in {
  imports = [(import ../arr-common/mkArrServiceModule.nix "prowlarr" extraConfigOptions {inherit config lib pkgs;})];

  config = {
    sops.secrets = {
      "indexer-api-keys/DrunkenSlug" = {mode = "0440";};
    };

    server.prowlarr = {
      usesDynamicUser = true;
      config = {
        apiVersion = lib.mkDefault "v1";
        hostConfig = {
          port = lib.mkDefault 9696;
          branch = lib.mkDefault "master";
        };

        indexers = [
          {
            name = "DrunkenSlug";
            apiKeyPath = config.sops.secrets."indexer-api-keys/DrunkenSlug".path;
          }
        ];
      };
    };

    systemd.services."prowlarr-indexers" = mkProwlarrIndexersService "prowlarr" config.server.prowlarr.config;
  };
}
