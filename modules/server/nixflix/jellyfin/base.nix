{
  flake.modules.nixos.homelab = { config, lib, ... }: {
    sops.secrets."jellyfin/kiri-password" = { };
    sops.secrets."jellyfin/guest-password" = { };
    sops.secrets."jellyfin/api-key" = { };

    system.backup.paths = [ config.nixflix.jellyfin.dataDir ];

    nixflix.jellyfin = {
      enable = true;
      apiKey._secret = config.sops.secrets."jellyfin/api-key".path;
      subdomain = "watch";
      network.enableRemoteAccess = true;
      branding = {
        customCss = ''
          @import url("https://theme-park.dev/css/base/jellyfin/${config.nixflix.theme.name}.css");
        '';
      };

      users = {
        admin = {
          mutable = false;
          policy.isAdministrator = true;
          password = {
            _secret = config.sops.secrets."jellyfin/kiri-password".path;
          };
        };
        guest = {
          mutable = false;
          policy.isAdministrator = lib.mkForce false;
          password = {
            _secret = config.sops.secrets."jellyfin/guest-password".path;
          };
        };
      };

      libraries =
        let
          subtitleSettings = {
            subtitleDownloadLanguages = [
              "eng"
              "spa"
            ];
            requirePerfectSubtitleMatch = true;
          };
        in
        {
          Shows = subtitleSettings;
          Anime = subtitleSettings;
          Movies = subtitleSettings;
          Music = lib.mkForce null;
        };

      plugins = {
        "Jellyfin Enhanced" = {
          enable = true;
        };
      };
    };
  };
}
