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

        ddns.domains = [ "headscale.walawren.com" ];

        # For now, you need create the headscale server first then register
        # the node with the server
        tailscale.enable = false;
      };

      # For now, you need create the headscale server first then register
      # the node with the server
      # server.adguardhome.serverIP = "tailscale server goes here";

      services.nginx.enable = true;
      networking.firewall.allowedTCPPorts = [ 443 ];
    };
}
