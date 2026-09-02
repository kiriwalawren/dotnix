{
  flake.modules.nixos.homelab =
    { config, ... }:
    {
      sops.secrets = {
        "lastfm/api-key" = { };
        "lastfm/shared-secret" = { };
        "navidrome/passwords/kiri" = { };
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

      system.backup.paths = [ config.nixflix.navidrome.settings.DataFolder ];

      services.navidrome.environmentFile = config.sops.templates."navidrome.env".path;

      nixflix.beets = {
        enable = true;
        settings.lyrics.auto = true;
      };

      nixflix.navidrome = {
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
}
