{
  flake.modules.nixos.homelab =
    { config, ... }:
    {
      sops.secrets = {
        "sonarr-anime/api_key" = { };
        "sonarr-anime/password" = { };
      };

      system.backup.paths = [ config.nixflix.sonarr-anime.dataDir ];

      nixflix.sonarr-anime = {
        enable = true;
        subdomain = "anime";

        config = {
          apiKey._secret = config.sops.secrets."sonarr-anime/api_key".path;
          hostConfig.password._secret = config.sops.secrets."sonarr-anime/password".path;
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
