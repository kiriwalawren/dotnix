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
        "${config.nixflix.mediaDir}/tv"
        "${config.nixflix.mediaDir}/anime"
      ];
      config = {
        apiKeyPath = config.sops.secrets."sonarr/api_key".path;
        hostConfig.passwordPath = config.sops.secrets."sonarr/password".path;
      };
    };
  };
}
