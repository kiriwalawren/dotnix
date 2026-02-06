{
  config,
  lib,
  theme,
  ...
}:
with lib; let
  cfg = config.server.nixflix;
in {
  imports = [
    ./jellyfin.nix
    ./jellyseerr.nix
    ./lidarr.nix
    ./mullvad.nix
    ./prowlarr.nix
    ./radarr.nix
    ./sabnzbd.nix
    ./sonarr.nix
    ./sonarr-anime.nix
  ];

  options.server.nixflix = {enable = mkEnableOption "nixflix media server configuration";};

  config = mkIf cfg.enable {
    nixflix = {
      enable = true;
      mediaUsers = [config.user.name];

      theme = {
        enable = true;
        name = "catppuccin-${theme.variant}";
      };

      nginx.enable = true;
      postgres.enable = true;

      recyclarr = {
        enable = true;
        cleanupUnmanagedProfiles = true;
      };
    };
  };
}
