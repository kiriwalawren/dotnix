{
  flake.modules.nixos.homelab = { config, ... }: {
    sops.secrets = {
      "aurral/api-key" = { };
      "aurral/kiri-username" = { };
      "aurral/kiri-password" = { };
    };

    nixflix.aurral = {
      enable = true;
      subdomain = "music2";

      settings = {
        users.kiri = {
          username = config.sops.secrets."aurral/kiri-username".path;
          password = config.sops.secrets."aurral/kiri-password".path;
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
    };
  };
}
