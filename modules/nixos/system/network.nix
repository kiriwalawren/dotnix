{
  config,
  name,
  ...
}: {
  config = {
    networking = {
      hostName = name;

      networkmanager.enable = !config.wsl.enable;
      firewall.enable = true;
      enableIPv6 = true;
    };
  };
}
