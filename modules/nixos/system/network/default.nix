{
  config,
  name,
  ...
}:
{
  imports = [
    ./ddns.nix
    ./tailscale.nix
  ];

  config = {
    networking = {
      hostName = name;

      networkmanager = {
        enable = !config.wsl.enable;
        wifi.backend = "iwd";
      };

      wireless.iwd.enable = true;

      firewall = {
        enable = true;
        # For spotify connect, chromecast, and mDNS
        allowedUDPPorts = [
          5353
          1900
        ];
      };
      enableIPv6 = true;
    };
  };
}
