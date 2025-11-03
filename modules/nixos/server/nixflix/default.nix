{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.server.nixflix;
in {
  imports = [
    ./lidarr.nix
    ./mullvad.nix
    ./prowlarr.nix
    ./radarr.nix
    ./sabnzbd.nix
    ./sonarr.nix
  ];

  options.server.nixflix = {
    enable = mkEnableOption "nixflix media server configuration";
  };

  config = mkIf cfg.enable {
    nixflix = {
      enable = true;
      serviceNameIsUrlBase = true;
      nginx.enable = true;
      postgres.enable = true;
      mediaUsers = [config.user.name];
    };
  };
}
