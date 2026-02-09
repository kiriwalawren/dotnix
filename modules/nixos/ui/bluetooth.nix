{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.ui.bluetooth;
in
{
  options.ui.bluetooth = {
    enable = mkEnableOption "bluetooth";
  };

  config = mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    services.blueman.enable = true;

    # PS5 DualSense Control
    environment.systemPackages = [ pkgs.dualsensectl ];
  };
}
