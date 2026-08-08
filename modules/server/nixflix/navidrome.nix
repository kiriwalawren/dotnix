{
  flake.modules.nixos.homelab =
    { config, ... }:
    {
      sops.secrets = {
        "lastfm/api-key" = { };
        "lastfm/shared-secret" = { };
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

      nixflix.navidrome = {
        enable = true;
        subdomain = "listen";

        settings = {
          DefaultTheme = "Catppuccin Macchiato";
        };
      };
    };
}
