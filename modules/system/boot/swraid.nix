{
  flake.modules.nixos.base =
    { config, lib, ... }:
    let
      hasRaid = builtins.any (disk: disk ? raidLevel && disk.raidLevel != null) (
        builtins.attrValues config.system.disks
      );
    in
    {
      boot = lib.mkIf hasRaid {
        # Configure mdadm for RAID
        swraid = {
          enable = true;
          mdadmConf = ''
            MAILADDR root
          '';
        };
      };
    };
}
