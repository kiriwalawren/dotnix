{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.server.nixflix.enable {
    sops.secrets.mullvad-account-number = {};
    nixflix.mullvad = {
      # Disable for now, the timing is off and this fails during the initial install
      enable = true;
      accountNumberPath = config.sops.secrets.mullvad-account-number.path;
      location = ["us" "nyc"];
      dns = [
        # AdGuard DNS (primary ad-blocking DNS)
        "94.140.14.14"
        "94.140.15.15"
        # Control D Ads & Trackers (backup ad-blocking DNS)
        "76.76.2.2"
        "76.76.10.2"
        # # Quad9 (fallback with malware blocking)
        # "9.9.9.9"
        # "149.112.112.112"
      ];
      killSwitch = {
        enable = true;
        allowLan = true;
      };
    };
  };
}
