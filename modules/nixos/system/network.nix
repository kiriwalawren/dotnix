{
  config,
  name,
  ...
}: {
  config = {
    networking = {
      hostName = name;

      networkmanager = {
        enable = !config.wsl.enable;
        wifi.backend = "iwd";
      };

      wireless.iwd.enable = true;

      firewall.enable = true;
      enableIPv6 = true;
    };
  };
}
