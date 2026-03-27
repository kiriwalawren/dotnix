{
  flake.modules.nixos.nixflix =
    { config, ... }:
    {
      sops.secrets.mullvad-account-number = { };
      nixflix.mullvad = {
        enable = true;
        enableIPv6 = true;
        accountNumber = {
          _secret = config.sops.secrets.mullvad-account-number.path;
        };
        location = [
          "us"
          "nyc"
        ];
        killSwitch = {
          enable = true;
          allowLan = true;
        };
        tailscale = {
          enable = config.services.tailscale.enable;
          exitNode = true;
        };
      };
    };
}
