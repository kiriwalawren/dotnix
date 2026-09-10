{
  flake.modules.nixos.homelab =
    { config, lib, ... }:
    {
      sops.secrets = {
        "slskd/username" = { };
        "slskd/password" = { };
        "slskd/api-key" = { };
      };

      system.backup.paths = [
        config.nixflix.slskd.dataDir
      ];

      systemd.services.slskd.vpnConfinement = {
        vpnNamespace = lib.mkForce "slskd";
      };

      nixflix.slskd = {
        enable = false;
        subdomain = "slskd";
        username._secret = config.sops.secrets."slskd/username".path;
        password._secret = config.sops.secrets."slskd/password".path;
        apiKey._secret = config.sops.secrets."slskd/api-key".path;
      };
    };
}
