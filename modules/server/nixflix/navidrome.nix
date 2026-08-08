{
  flake.modules.nixos.homelab =
    { config, ... }:
    {
      system.backup.paths = [ config.nixflix.navidrome.settings.DataFolder ];

      nixflix.navidrome = {
        enable = true;
        subdomain = "listen";

        settings = {
          DefaultTheme = "Catppuccin Macchiato";
        };
      };
    };
}
