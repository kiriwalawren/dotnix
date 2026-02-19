{
  flake.modules.nixos.bluetooth =
    { pkgs, ... }:
    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };

      # PS5 DualSense Control
      environment.systemPackages = [
        pkgs.dualsensectl
        pkgs.bluetui
      ];
    };

  flake.modules.homeManager.bluetooth =
    { pkgs, lib, ... }:
    {
      programs.waybar.settings.mainBar.bluetooth.on-click =
        "pkill bluetui || ${pkgs.kitty}/bin/kitty --class=bluetui ${lib.getExe pkgs.bluetui}";

      wayland.windowManager.hyprland.settings.windowrule = [
        "match:class bluetui, float on, center on, size 1100 700, pin on, stay_focused on"
      ];
    };
}
