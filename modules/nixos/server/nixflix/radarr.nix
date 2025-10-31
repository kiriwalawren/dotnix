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
      };
    };
  };
}
