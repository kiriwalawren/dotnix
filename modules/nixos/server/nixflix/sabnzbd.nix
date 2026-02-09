{
  config,
  lib,
  ...
}:
with lib;
{
  config = mkIf config.server.nixflix.enable {
    sops.secrets = {
      "sabnzbd/username" = { };
      "sabnzbd/password" = { };
      "sabnzbd/api_key" = { };
      "sabnzbd/nzb_key" = { };
      "usenet/eweka/username" = { };
      "usenet/eweka/password" = { };
      "usenet/newsgroupdirect/username" = { };
      "usenet/newsgroupdirect/password" = { };
    };

    nixflix.sabnzbd = {
      enable = true;

      settings = {
        misc = {
          username = {
            _secret = config.sops.secrets."sabnzbd/username".path;
          };
          password = {
            _secret = config.sops.secrets."sabnzbd/password".path;
          };
          api_key = {
            _secret = config.sops.secrets."sabnzbd/api_key".path;
          };
          nzb_key = {
            _secret = config.sops.secrets."sabnzbd/nzb_key".path;
          };
        };
        servers = [
          {
            name = "Eweka";
            host = "sslreader.eweka.nl";
            port = 563;
            username = {
              _secret = config.sops.secrets."usenet/eweka/username".path;
            };
            password = {
              _secret = config.sops.secrets."usenet/eweka/password".path;
            };
            connections = 20;
            ssl = true;
            priority = 0;
          }
          {
            name = "NewsgroupDirect";
            host = "news.newsgroupdirect.com";
            port = 563;
            username = {
              _secret = config.sops.secrets."usenet/newsgroupdirect/username".path;
            };
            password = {
              _secret = config.sops.secrets."usenet/newsgroupdirect/password".path;
            };
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
