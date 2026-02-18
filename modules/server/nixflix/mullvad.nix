{
  flake.modules.nixos.nixflix =
    {
      config,
      ...
    }:
    {
      sops.secrets.mullvad-account-number = { };
      nixflix.mullvad = {
        # Disable for now, the timing is off and this fails during the initial install
        enable = true;
        enableIPv6 = true;
        accountNumber = {
          _secret = config.sops.secrets.mullvad-account-number.path;
        };
        location = [
          "us"
          "nyc"
        ];
        dns = [
          config.server.adguardhome.serverIP
        ];
        killSwitch = {
          enable = true;
          allowLan = true;
        };
      };
    };
}
