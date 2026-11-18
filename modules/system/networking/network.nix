{
  flake.modules.nixos.base = { config, ... }: {
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

  flake.modules.homeManager.gui = { pkgs, ... }: { home.packages = [ pkgs.impala ]; };
}
