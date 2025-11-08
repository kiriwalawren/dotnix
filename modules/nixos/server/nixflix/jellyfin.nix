{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.server.nixflix.enable {
    sops.secrets = {
      "jellyfin/api_key" = {};
    };

    nixflix.jellyfin = {
      enable = true;
      apiKeyPath = config.sops.secrets."jellyfin/api_key".path;
    };
  };
}
