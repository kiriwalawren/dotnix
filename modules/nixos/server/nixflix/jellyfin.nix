{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.server.nixflix.enable {
    sops.secrets = {
      "jellyfin/api_key" = {};
      "jellyfin/admin_password_hash" = {};
    };

    nixflix.jellyfin = {
      enable = true;
      network.enableRemoteAccess = false;
      users = {
        admin = {
          mutable = false;
          permissions.isAdministrator = true;
          hashedPasswordFile = config.sops.secrets."jellyfin/admin_password_hash".path;
        };
      };
    };
  };
}
