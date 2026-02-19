{
  flake.modules.nixos.base =
    { config, lib, ... }:
    let
      hasRaid = builtins.any (disk: disk ? raidLevel && disk.raidLevel != null) (
        builtins.attrValues config.system.disks
      );
    in
    {
      # Configure mdadm for RAID
      boot.swraid = lib.mkIf hasRaid {
        enable = true;
        mdadmConf = ''
          MAILADDR root
        '';
      };
    };
}
