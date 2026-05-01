{
  flake.modules.nixos.homelab =
    { config, ... }:
    {
      sops.secrets."seerr/api_key" = { };

      system.backup.paths = [ config.nixflix.seerr.dataDir ];

      nixflix.seerr = {
        enable = true;
        subdomain = "request";
        apiKey._secret = config.sops.secrets."seerr/api_key".path;
      };
    };
}
