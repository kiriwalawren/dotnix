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
        firewall.enable = true;
        enableIPv6 = true;
      };
    };

  flake.modules.homeManager.gui =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.impala ];

      wayland.windowManager.hyprland.settings.windowrule = [
        "match:class impala, float on, center on, size 1100 700, pin on, stay_focused on"
      ];
    };
}
