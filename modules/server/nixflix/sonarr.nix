{
  flake.modules.nixos.nixflix =
    { config, ... }:
    {
      sops.secrets = {
        "sonarr/api_key" = { };
        "sonarr/password" = { };
      };

      nixflix.sonarr = {
        enable = true;
        subdomain = "tv";

        config = {
          apiKey = {
            _secret = config.sops.secrets."sonarr/api_key".path;
          };
          hostConfig.password = {
            _secret = config.sops.secrets."sonarr/password".path;
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
