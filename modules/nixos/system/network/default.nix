{
  config,
  name,
  ...
}: {
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
        allowedUDPPorts = [5353 1900];
      };
      enableIPv6 = true;
    };

    # Enable Avahi for mDNS/Zeroconf service discovery (Spotify Connect, etc.)
    services.avahi = {
      enable = !config.wsl.enable;
      nssmdns4 = true;
      nssmdns6 = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };
  };
}
