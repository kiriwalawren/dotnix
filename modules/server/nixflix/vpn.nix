{
  flake.modules.nixos.homelab =
    { config, ... }:
    {
      sops.secrets."wireguard-confs/mullvad" = { };
      nixflix.vpn = {
        enable = true;
        wgConfFile = config.sops.secrets."wireguard-confs/mullvad".path;
        # tailscale = {
        #   inherit (config.services.tailscale) enable;
        #   exitNode = true;
        # };
      };
    };
}
