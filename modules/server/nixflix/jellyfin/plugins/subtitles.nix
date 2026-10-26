{
  flake.modules.nixos.homelab = { config, ... }: {
    sops.secrets."opensubtitles-com/api-key" = { };
    sops.secrets."opensubtitles-com/password" = { };

    nixflix.jellyfin.plugins = {
      subbuzz = {
        enable = true;
        config = {
          OpenSubApiKey._secret = config.sops.secrets."opensubtitles-com/api-key".path;
          OpenSubUserName = "kiriwalawren.com";
          OpenSubPassword._secret = config.sops.secrets."opensubtitles-com/password".path;
          EnableOpenSubtitles = true;
          EnableYifySubtitles = true;
          Cache.SubLifeInMinutes = "Always";
        };
      };

      "Subtitle Extract" = {
        enable = true;
        config.ExtractionDuringLibraryScan = true;
      };
    };
  };
}
