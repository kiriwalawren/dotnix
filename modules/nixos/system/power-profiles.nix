{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    system.power-profiles.enable = lib.mkEnableOption "automatic power profile switching";
  };

  config = lib.mkIf config.system.power-profiles.enable {
    # Enable power-profiles-daemon with performance as default
    services.power-profiles-daemon = {
      enable = true;
    };

    # Set default profile to performance
    systemd.services.power-profiles-daemon.environment = {
      PPD_DEFAULT_PROFILE = "performance";
    };

    # Udev rules to detect AC adapter state changes (for laptops)
    # These will only trigger on systems with batteries
    services.udev.extraRules = ''
      # When AC adapter is unplugged, switch to balanced
      SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.bash}/bin/bash -c '${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver'"

      # When AC adapter is plugged in, switch to performance
      SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.bash}/bin/bash -c '${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance'"
    '';
  };
}
