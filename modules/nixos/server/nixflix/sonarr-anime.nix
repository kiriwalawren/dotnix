{
  config,
  lib,
  ...
}:
with lib;
{
  config = mkIf config.server.nixflix.enable {
    sops.secrets = {
      "sonarr-anime/api_key" = { };
      "sonarr-anime/password" = { };
    };

    nixflix.sonarr-anime = {
      enable = true;
      subdomain = "anime";

      config = {
        apiKey = {
          _secret = config.sops.secrets."sonarr-anime/api_key".path;
        };
        hostConfig.password = {
          _secret = config.sops.secrets."sonarr-anime/password".path;
        };
        delayProfiles = [
          {
            enableUsenet = true;
            enableTorrent = true;
            preferredProtocol = "usenet";
            usenetDelay = 0;
            torrentDelay = 0;
            bypassIfHighestQuality = true;
            bypassIfAboveCustomFormatScore = false;
            minimumCustomFormatScore = 0;
            order = 2147483647;
            tags = [ ];
            id = 1;
          }
        ];
      };
    };
  };
}
