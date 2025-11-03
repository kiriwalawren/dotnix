{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.server.nixflix.enable {
    sops.secrets = {
      "sabnzbd/api_key" = {
        inherit (cofig.nixflix.sabnzbd) group;
        owner = config.nixflix.sabnzbd.user;
      };
      "usenet/eweka/username" = {};
      "usenet/eweka/password" = {};
      "usenet/newsgroupdirect/username" = {};
      "usenet/newsgroupdirect/password" = {};
    };

    nixflix.sabnzbd = {
      enable = true;
      apiKeyPath = config.sops.secrets."sabnzbd/api_key".path;

      environmentSecrets = [
        {
          env = "EWEKA_USERNAME";
          inherit (config.sops.secrets."usenet/eweka/username") path;
        }
        {
          env = "EWEKA_PASSWORD";
          inherit (config.sops.secrets."usenet/eweka/password") path;
        }
        {
          env = "NGD_USERNAME";
          inherit (config.sops.secrets."usenet/newsgroupdirect/username") path;
        }
        {
          env = "NGD_PASSWORD";
          inherit (config.sops.secrets."usenet/newsgroupdirect/password") path;
        }
      ];

      settings = {
        servers = [
          {
            name = "Eweka";
            host = "sslreader.eweka.nl";
            port = 563;
            username = "$EWEKA_USERNAME";
            password = "$EWEKA_PASSWORD";
            connections = 20;
            ssl = true;
            priority = 0;
          }
          {
            name = "NewsgroupDirect";
            host = "news.newsgroupdirect.com";
            port = 563;
            username = "$NGD_USERNAME";
            password = "$NGD_PASSWORD";
            connections = 10;
            ssl = true;
            priority = 1;
            optional = true;
            backup = true;
          }
        ];
      };
    };
  };
}
