{
  flake.modules.nixos.homelab = { config, ... }: {
    sops.secrets."notif/discord-webhook-url" = { };
    sops.secrets."notif/telegram/bot-token" = { };

    nixflix.notif = {
      discord = {
        webHookUrl._secret = config.sops.secrets."notif/discord-webhook-url".path;

        radarr = {
          enable = true;
          onMovieAdded = false;
          onMovieDelete = false;
          onMovieFileDelete = false;
          onMovieFileDeleteForUpgrade = false;
        };

        sonarr = {
          enable = true;
          onSeriesAdd = false;
          onSeriesDelete = false;
          onEpisodeFileDelete = false;
          onEpisodeFileDeleteForUpgrade = false;
        };

        sonarr-anime = {
          enable = true;
          onSeriesAdd = false;
          onSeriesDelete = false;
          onEpisodeFileDelete = false;
          onEpisodeFileDeleteForUpgrade = false;
        };

        lidarr = {
          enable = true;
          onTrackRetag = false;
        };

        seerr.enable = true;
      };

      telegram = {
        botToken._secret = config.sops.secrets."notif/telegram/bot-token".path;
        chatId = "8693797752";

        radarr = {
          enable = true;
          onMovieAdded = false;
          onMovieDelete = false;
          onMovieFileDelete = false;
          onMovieFileDeleteForUpgrade = false;
        };

        sonarr = {
          enable = true;
          onSeriesAdd = false;
          onSeriesDelete = false;
          onEpisodeFileDelete = false;
          onEpisodeFileDeleteForUpgrade = false;
        };

        sonarr-anime = {
          enable = true;
          onSeriesAdd = false;
          onSeriesDelete = false;
          onEpisodeFileDelete = false;
          onEpisodeFileDeleteForUpgrade = false;
        };

        lidarr.enable = true;

        seerr = {
          enable = true;
          botUsername = "airelas_server_bot";
        };
      };
    };
  };
}
