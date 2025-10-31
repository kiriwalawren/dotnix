{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.server.nixflix.enable {
    sops.secrets = {
      "sonarr/api_key" = {};
      "sonarr/password" = {};
    };

    nixflix.sonarr = {
      enable = true;
      mediaDirs = [
        {dir = "${config.nixflix.mediaDir}/tv";}
        {dir = "${config.nixflix.mediaDir}/anime";}
      ];
      config = {
        apiKeyPath = config.sops.secrets."sonarr/api_key".path;
        hostConfig.passwordPath = config.sops.secrets."sonarr/password".path;
      };
    };
  };
}
