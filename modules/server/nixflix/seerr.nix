{
  flake.modules.nixos.nixflix =
    { config, ... }:
    {
      sops.secrets."seerr/api_key" = { };

      nixflix.seerr = {
        enable = true;
        subdomain = "request";
        apiKey._secret = config.sops.secrets."seerr/api_key".path;
      };
    };
}
