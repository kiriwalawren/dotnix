{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.server.nixflix.enable {
    sops.secrets."jellyseerr/api_key" = {};

    nixflix.jellyseerr = {
      enable = true;
      apiKey = {_secret = config.sops.secrets."jellyseerr/api_key".path;};

      externalBaseUrl = "http://home-server";
    };
  };
}
