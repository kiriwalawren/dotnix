{
  flake.modules.nixos.nixflix =
    { config, ... }:
    {
      sops.secrets."jellyfin/kiri_password" = { };
      sops.secrets."jellyfin/api_key" = { };

      nixflix.jellyfin = {
        enable = true;
        apiKey._secret = config.sops.secrets."jellyfin/api_key".path;
        subdomain = "watch";
        network.enableRemoteAccess = true;
        users = {
          Kiri = {
            mutable = false;
            policy.isAdministrator = true;
            password._secret = config.sops.secrets."jellyfin/kiri_password".path;
          };
        };
      };
    };
}
