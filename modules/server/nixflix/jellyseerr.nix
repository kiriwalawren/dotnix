{
  flake.modules.nixos.nixflix =
    {
      config,
      ...
    }:
    {
      sops.secrets."jellyseerr/api_key" = { };

      nixflix.jellyseerr = {
        enable = true;
        subdomain = "request";
        apiKey = {
          _secret = config.sops.secrets."jellyseerr/api_key".path;
        };
      };
    };
}
