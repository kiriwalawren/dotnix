{
  flake.modules.nixos.nixflix =
    { config, ... }:
    {
      sops.secrets."jellyfin/kiri_password" = { };

      nixflix.jellyfin = {
        enable = true;
        subdomain = "watch";
        network.enableRemoteAccess = false;
        users = {
          Kiri = {
            mutable = false;
            policy.isAdministrator = true;
            password = {
              _secret = config.sops.secrets."jellyfin/kiri_password".path;
            };
          };
        };
        system.pluginRepositories = [
          {
            content = {
              enabled = true;
              name = "Moonfin";
              url = "https://raw.githubusercontent.com/Moonfin-Client/Plugin/refs/heads/master/manifest.json";
            };
          }
        ];
      };
    };
}
