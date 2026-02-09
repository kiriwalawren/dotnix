{
  config,
  lib,
  ...
}:
with lib;
{
  config = mkIf config.server.nixflix.enable {
    sops.secrets."jellyfin/kiri_password" = { };

    nixflix.jellyfin = {
      enable = true;
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
    };
  };
}
