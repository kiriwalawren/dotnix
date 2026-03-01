{
  configurations.nixos.vm-test.modules.configuration =
    { lib, ... }:
    {
      imports = [
        ./_hardware-configuration.nix
      ];

      networking.hostName = "vm-test";

      system = {
        stateVersion = "25.11";

        disks."/" = {
          devices = [ "/dev/vda" ];
          encrypt = true;
        };

        disks."/data" = {
          devices = [
            "/dev/vdb"
            "/dev/vdc"
          ];
          raidLevel = 1;
          encrypt = true;
        };
      };

      nixflix.nginx.domain = lib.mkForce "vm";
    };
}
