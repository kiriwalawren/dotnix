{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.server.nixflix.enable {
    sops.secrets = {
      "sabnzbd/api_key" = {
        inherit (config.nixflix.sabnzbd) group;
        owner = config.nixflix.sabnzbd.user;
      };
      "sabnzbd/nzb_key" = {
        inherit (config.nixflix.sabnzbd) group;
        owner = config.nixflix.sabnzbd.user;
      };
      "usenet/eweka/username" = {
        inherit (config.nixflix.sabnzbd) group;
        owner = config.nixflix.sabnzbd.user;
      };
      "usenet/eweka/password" = {
        inherit (config.nixflix.sabnzbd) group;
        owner = config.nixflix.sabnzbd.user;
      };
      "usenet/newsgroupdirect/username" = {
        inherit (config.nixflix.sabnzbd) group;
        owner = config.nixflix.sabnzbd.user;
      };
      "usenet/newsgroupdirect/password" = {
        inherit (config.nixflix.sabnzbd) group;
        owner = config.nixflix.sabnzbd.user;
      };
    };

    nixflix.sabnzbd = {
      enable = true;

      settings = {
        misc = {
          api_key = {_secret = config.sops.secrets."sabnzbd/api_key".path;};
          nzb_api_key = {_secret = config.sops.secrets."sabnzbd/nzb_key".path;};
        };
        servers = [
          {
            name = "Eweka";
            host = "sslreader.eweka.nl";
            port = 563;
            username = {_secret = config.sops.secrets."usenet/eweka/username".path;};
            password = {_secret = config.sops.secrets."usenet/eweka/password".path;};
            connections = 20;
            ssl = true;
            priority = 0;
          }
          {
            name = "NewsgroupDirect";
            host = "news.newsgroupdirect.com";
            port = 563;
            username = {_secret = config.sops.secrets."usenet/newsgroupdirect/username".path;};
            password = {_secret = config.sops.secrets."usenet/newsgroupdirect/password".path;};
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
