{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.server.nixflix.enable {
    sops.secrets = {
      "jellyfin/api_key" = {};
      "jellyfin/admin_password" = {};
    };

    nixflix.jellyfin = {
      enable = true;
      network.enableRemoteAccess = false;
      apikeys.default = config.sops.secrets."jellyfin/api_key".path;
      users = {
        admin = {
          mutable = false;
          policy.isAdministrator = true;
          passwordFile = config.sops.secrets."jellyfin/admin_password".path;
        };
      };
    };
  };
}
