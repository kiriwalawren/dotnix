{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.server.nixflix.enable {
    sops.secrets = {
      "radarr/api_key" = {};
      "radarr/password" = {};
    };

    nixflix.radarr = {
      enable = true;
      config = {
        apiKeyPath = config.sops.secrets."radarr/api_key".path;
        hostConfig.passwordPath = config.sops.secrets."radarr/password".path;
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
            tags = [];
            id = 1;
          }
        ];
      };
    };
  };
}
