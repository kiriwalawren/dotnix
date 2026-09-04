{
  flake.modules.nixos.homelab =
    { config, ... }:
    {
      sops.secrets = {
        "lastfm/api-key" = { };
        "lastfm/shared-secret" = { };
        "navidrome/passwords/kiri" = { };
        "slskd/username" = { };
        "slskd/password" = { };
        "slskd/api-key" = { };
      };

      sops.templates."navidrome.env" = {
        owner = config.nixflix.navidrome.user;
        group = config.nixflix.navidrome.group;
        mode = "0440";
        content = ''
          ND_LASTFM_APIKEY=${config.sops.placeholder."lastfm/api-key"}
          ND_LASTFM_SECRET=${config.sops.placeholder."lastfm/shared-secret"}
        '';
      };

      system.backup.paths = [
        config.nixflix.navidrome.settings.DataFolder
        config.nixflix.slskd.dataDir
      ];

      services.navidrome.environmentFile = config.sops.templates."navidrome.env".path;

      nixflix = {
        slskd = {
          enable = true;
          subdomain = "slskd";
          username._secret = config.sops.secrets."slskd/username".path;
          password._secret = config.sops.secrets."slskd/password".path;
          apiKey._secret = config.sops.secrets."slskd/api-key".path;
        };

        droppedneedle = {
          enable = true;
          subdomain = "music2";
        };

        navidrome = {
          enable = true;
          subdomain = "listen";

          users.Kiri = {
            isAdmin = true;
            mutable = false;
            userName = "kiri";
            password._secret = config.sops.secrets."navidrome/passwords/kiri".path;
          };

          settings = {
            DefaultTheme = "Catppuccin Macchiato";
          };
        };
      };
    };
}
