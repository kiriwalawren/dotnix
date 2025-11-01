{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.server.nixflix.enable {
    sops.secrets = {
      "lidarr/api_key" = {};
      "lidarr/password" = {};
    };

    nixflix.lidarr = {
      enable = true;
      config = {
        apiKeyPath = config.sops.secrets."lidarr/api_key".path;
        hostConfig.passwordPath = config.sops.secrets."lidarr/password".path;
      };
    };
  };
}
