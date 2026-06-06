{
  flake.modules.nixos.homelab =
    { config, ... }:
    {
      system.backup.paths = [ config.nixflix.maintainerr.dataDir ];

      nixflix.maintainerr = {
        enable = true;
        subdomain = "cleanup";
      };
    };
}
