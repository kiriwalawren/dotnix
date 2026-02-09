{
  config,
  lib,
  ...
}:
with lib;
{
  config = mkIf config.server.nixflix.enable {
    sops.secrets = {
      "lidarr/api_key" = { };
      "lidarr/password" = { };
    };

    nixflix.lidarr = {
      enable = true;
      config = {
        apiKey = {
          _secret = config.sops.secrets."lidarr/api_key".path;
        };
        hostConfig.password = {
          _secret = config.sops.secrets."lidarr/password".path;
        };
        delayProfiles = [
          {
            enableUsenet = true;
            enableTorrent = true;
            preferredProtocol = "usenet";
            usenetDelay = 0;
            torrentDelay = 360;
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
