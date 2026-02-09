{
  config,
  lib,
  ...
}:
let
  cfg = config.system.disks;
  helpers = import ./lib.nix { inherit lib; };

  diskGroupModule =
    { name, ... }:
    {
      options = {
        devices = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "List of device paths for this disk group";
        };

        type = lib.mkOption {
          type = lib.types.enum [
            "os"
            "data"
          ];
          default = if name == "/" then "os" else "data";
          description = "Type of disk group: 'os' (BTRFS with subvolumes) or 'data' (EXT4)";
        };

        raidLevel = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.enum [
              0
              1
              5
              6
              10
            ]
          );
          default = null;
          description = "RAID level: null (no RAID), 0, 1, 5, 6, or 10";
        };

        withSwap = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable BTRFS swapfile (only for type='os')";
        };

        swapSize = lib.mkOption {
          type = lib.types.int;
          default = 4;
          description = "Swap size in GB";
        };

        encryptDrives = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable LUKS encryption for this disk group";
        };

        encryptionPasswordFile = lib.mkOption {
          type = lib.types.str;
          default = "/tmp/disk-secret.key";
          description = "Path to encryption password file";
        };
      };
    };

  # Minimum device count for each RAID level
  minDevicesForRaid = {
    "0" = 2;
    "1" = 2;
    "5" = 3;
    "6" = 4;
    "10" = 4;
  };

  mkAssertions =
    mountPoint: group:
    let
      deviceCount = builtins.length group.devices;
      minDevices = if group.raidLevel != null then minDevicesForRaid."${toString group.raidLevel}" else 1;
    in
    [
      {
        assertion = builtins.isList group.devices && deviceCount > 0;
        message = "system.disks.\"${mountPoint}\": devices must be a non-empty list";
      }
      {
        assertion = group.raidLevel == null || deviceCount >= minDevices;
        message = "system.disks.\"${mountPoint}\": RAID ${toString group.raidLevel} requires at least ${toString minDevices} devices, but only ${toString deviceCount} provided";
      }
      {
        assertion = group.raidLevel != 10 || (lib.mod deviceCount 2) == 0;
        message = "system.disks.\"${mountPoint}\": RAID 10 requires an even number of devices, got ${toString deviceCount}";
      }
      {
        assertion = !group.withSwap || group.type == "os";
        message = "system.disks.\"${mountPoint}\": withSwap is only supported for type='os' (BTRFS), not type='${group.type}'";
      }
      {
        assertion =
          !(
            mountPoint == "/"
            && group.raidLevel != null
            && group.encryptDrives
            && config.system.encryption.tpm2.enable
          );
        message = "system.disks.\"/\": encryption with TPM2/lanzaboote cannot be enabled when RAID is configured on the root drive because lanzaboote doesn't support mirrored ESPs. Use standard GRUB instead.";
      }
    ];

  processedGroups = lib.mapAttrs (
    mountPoint: group:
    helpers.mkDiskContent {
      name = helpers.sanitizeMountPoint mountPoint;
      inherit (group)
        devices
        raidLevel
        withSwap
        swapSize
        encryptDrives
        encryptionPasswordFile
        ;
      diskType = group.type;
      inherit mountPoint;
    }
  ) cfg;

  allDisks = lib.foldl (acc: group: acc // group.disk) { } (lib.attrValues processedGroups);
  allMdadm = lib.foldl (acc: group: acc // group.mdadm) { } (lib.attrValues processedGroups);
  allAssertions = lib.flatten (lib.mapAttrsToList mkAssertions cfg);
in
{
  options = {
    system.disks = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule diskGroupModule);
      default = { };
      description = ''
        Disk groups keyed by mount point.
        Each disk group defines a set of devices that will be configured together,
        either as a single disk or as a RAID array.
      '';
      example = lib.literalExpression ''
        {
          "/" = {
            devices = ["/dev/nvme0n1"];
            encryptDrives = true;
          };
          "/data" = {
            devices = ["/dev/sdb" "/dev/sdc"];
            type = "data";
            raidLevel = 1;
            encryptDrives = true;
          };
        }
      '';
    };
  };

  config = lib.mkIf (cfg != { }) {
    assertions = allAssertions;

    disko.devices = {
      disk = allDisks;
    }
    // (lib.optionalAttrs (allMdadm != { }) {
      mdadm = allMdadm;
    });
  };
}
