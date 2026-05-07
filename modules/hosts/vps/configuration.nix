{
  configurations.nixos.vps.modules.configuration =
    { pkgs, inputs, ... }:
    {
      imports = [
        ./_hardware-configuration.nix
      ];

      networking = {
        hostName = "vps";
        firewall.allowedTCPPorts = [ 443 ];

        defaultGateway6 = {
          address = "fe80::1";
          interface = "enp1s0";
        };

        interfaces.enp1s0.ipv6.addresses = [
          {
            address = inputs.secrets.ipv6.vps;
            prefixLength = 64;
          }
        ];
      };

      documentation.man.enable = false;

      environment.systemPackages = [ pkgs.vim ];

      system = {
        stateVersion = "25.11";

        disks."/" = {
          devices = [ "/dev/sda" ];
        };

        ddns.enable = true;

        backup.paths = [ "/var/lib" ];
      };

      server.adguardhome.serverIP = "100.64.0.4";

      services.nginx.enable = true;
    };
}
