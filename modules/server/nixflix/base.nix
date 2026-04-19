{
  config,
  inputs,
  ...
}:
let
  user = config.user.name;
in
{
  flake.modules.nixos.homelab =
    { config, ... }:
    {
      imports = [
        inputs.nixflix.nixosModules.default
      ];
      sops.secrets."wireguard-confs/protonvpn" = { };

      system.backup.paths = [ config.nixflix.stateDir ];

      nixflix = {
        enable = true;
        mediaUsers = [ user ];

        theme = {
          enable = true;
          name = "catppuccin-${config.catppuccin.flavor}";
        };

        vpn = {
          enable = true;
          wgConfFile = config.sops.secrets."wireguard-confs/protonvpn".path;
        };

        nginx = {
          enable = true;
          addHostsEntries = false;
          inherit (config.system.ddns) domain;
          forceSSL = true;
          enableACME = true;
        };

        postgres.enable = true;

        recyclarr = {
          enable = true;
          radarrQuality = "4K";
          cleanupUnmanagedProfiles.enable = true;
        };
      };
    };
}
