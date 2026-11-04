{
  flake.modules.nixos.homelab = { config, ... }: {
    sops.secrets = {
      "aurral/api-key" = { };
      "aurral/admin-password" = { };
      "aurral/oidc-client-id" = { };
      "aurral/oidc-client-secret" = { };
    };

    nixflix.aurral = {
      enable = true;
      subdomain = "aurral";

      settings = {
        users.admin = {
          password._secret = config.sops.secrets."aurral/admin-password".path;
          role = "admin";

          permissions = {
            accessFlow = true;
            addArtist = true;
            addAlbum = true;
            changeMonitoring = true;
            deleteArtist = true;
            deleteAlbum = true;
            deleteTrack = true;
          };
        };
      };

      oidc = {
        enable = true;
        issuer = "https://auth.${config.system.ddns.domain}";
        clientId._secret = config.sops.secrets."aurral/oidc-client-id".path;
        clientSecret._secret = config.sops.secrets."aurral/oidc-client-secret".path;
        scopes = [
          "openid"
          "profile"
          "email"
          "groups"
        ];
        adminGroups = [ "admins" ];
      };
    };
  };
}
