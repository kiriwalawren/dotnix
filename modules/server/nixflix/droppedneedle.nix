{
  flake.modules.nixos.homelab =
    { config, ... }:
    {
      sops.secrets = {
        "droppedneedle/passwords/kiriwalawren" = { };
      };

      system.backup.paths = [
        config.nixflix.droppedneedle.dataDir
      ];

      nixflix.droppedneedle = {
        enable = true;
        subdomain = "music2";

        settings.users.Kiri = {
          userName = "kiriwalawren";
          role = "admin";
          password._secret = config.sops.secrets."droppedneedle/passwords/kiriwalawren".path;
        };
      };
    };
}
