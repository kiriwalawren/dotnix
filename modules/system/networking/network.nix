{
  flake.modules.nixos.base =
    { config, ... }:
    {
      networking = {
        networkmanager = {
          enable = !config.wsl.enable;
          wifi.backend = "iwd";
        };

        wireless.iwd.enable = true;

        firewall = {
          enable = true;
          # TODO: move to spotify implementation
          # For spotify connect, chromecast, and mDNS
          allowedUDPPorts = [
            5353
            1900
          ];
        };
        enableIPv6 = true;
      };
    };

  flake.module.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.impala ];

      # Waybar integration - override the network on-click
      programs.waybar.settings.mainBar.network.on-click =
        "pkill impala || ${pkgs.kitty}/bin/kitty --class=impala ${pkgs.impala}/bin/impala";

      wayland.windowManager.hyprland.settings.windowrule = [
        "match:class impala, float on, center on, size 1100 700, pin on, stay_focused on"
      ];
    };
}
