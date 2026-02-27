{
  configurations.nixos.vps.modules.configuration =
    { pkgs, ... }:
    {
      imports = [
        ./_hardware-configuration.nix
      ];

      networking.hostName = "vps";
      documentation.man.enable = false;

      environment.systemPackages = [ pkgs.vim ];

      system = {
        stateVersion = "25.11";

        disks."/" = {
          devices = [ "/dev/sda" ];
        };

        ddns.domain = "walawren.com";
      };

      server.adguardhome.serverIP = "100.64.0.4";

      services.nginx.enable = true;

      networking = {
        firewall.allowedTCPPorts = [ 443 ];
        defaultGateway6 = {
          address = "fe80::1";
          interface = "enp1s0";
        };
      };
    };
}
