{
  flake.modules.nixos.homelab = { config, pkgs, ... }: {
    sops.secrets = {
      "aurral/api-key" = { };
      "aurral/admin-password" = { };
      "aurral/oidc-client-id" = { };
      "aurral/oidc-client-secret" = { };
    };

    nixflix.aurral = {
      enable = true;
      subdomain = "aurral";
      package = pkgs.aurral.overrideAttrs (
        _finalAttrs: old: {
          version = "2.13.0-unstable-2026-11-16";
          src = pkgs.fetchFromGitHub {
            owner = "lklynet";
            repo = "aurral";
            rev = "0e87fc3f7218df4021ad8cd957da6ecdce355d60";
            hash = "sha256-wRGxNBF96GmMSxpzFxGpN3i/NC8gK8AePNEz+52jVto=";
          };
          pnpmDeps = old.pnpmDeps.overrideAttrs {
            outputHash = "sha256-JYk5RgLwe5bMENwIhPZm+PaDS0kYt6v4gTWDiucg2WQ=";
          };
          # Hub tests run wrangler, which hangs in the build sandbox.
          preCheck = "rm -r .tests/hub";
          meta = old.meta // {
            changelog = "https://github.com/lklynet/aurral/commit/0e87fc3f7218df4021ad8cd957da6ecdce355d60";
          };
        }
      );
      apiKey._secret = config.sops.secrets."aurral/api-key".path;

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

        lastfm = {
          apiKey._secret = config.sops.secrets."lastfm/api-key".path;
          apiSecret._secret = config.sops.secrets."lastfm/shared-secret".path;
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
