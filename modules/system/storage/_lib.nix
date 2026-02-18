{ lib }:
{
  mkBtrfsSubvolumes =
    {
      withSwap ? false,
      swapSize ? 4,
    }:
    {
      "/root" = {
        mountpoint = "/";
        mountOptions = [
          "compress=zstd"
          "noatime"
        ];
      };
      "/nix" = {
        mountpoint = "/nix";
        mountOptions = [
          "compress=zstd"
          "noatime"
        ];
      };
      "/swap" = lib.mkIf withSwap {
        mountpoint = "/.swapvol";
        swap.swapfile.size = "${toString swapSize}G";
      };
    };

  mkLuksWrapper =
    {
      name,
      passwordFile,
      content,
    }:
    {
      type = "luks";
      inherit name;
      settings.allowDiscards = true;
      inherit passwordFile content;
    };

  mkEspPartition = {
    priority = 1;
    name = "ESP";
    start = "1M";
    end = "512M";
    type = "EF00";
    content = {
      type = "filesystem";
      format = "vfat";
      mountpoint = "/boot/efi";
      mountOptions = [ "defaults" ];
    };
  };

  # ESP partition for mirrored boot setups (with custom mountpoint)
  mkEspPartitionWithMount = mountpoint: {
    priority = 1;
    name = "ESP";
    start = "1M";
    end = "512M";
    type = "EF00";
    content = {
      type = "filesystem";
      format = "vfat";
      inherit mountpoint;
      mountOptions = [ "defaults" ];
    };
  };

  # "/" → "main", "/data" → "data", "/mnt/storage" → "storage"
  sanitizeMountPoint =
    mountPoint:
    if mountPoint == "/" then
      "main"
    else
      let
        # Remove leading slash
        noLeadingSlash = lib.removePrefix "/" mountPoint;
        # Get last component of path
        parts = lib.splitString "/" noLeadingSlash;
        lastPart = lib.last parts;
      in
      lastPart;

  mkDiskContent =
    {
      name,
      devices,
      raidLevel,
      diskType, # "os" or "data"
      mountPoint,
      withSwap,
      swapSize,
      encryptDrives,
      encryptionPasswordFile,
    }:
    let
      helpers = import ./_lib.nix { inherit lib; };
      isRaid = raidLevel != null;
      isOsDisk = diskType == "os";

      filesystem = if diskType == "os" then "btrfs" else "ext4";

      mkFilesystemContent =
        {
          filesystem,
          mountpoint,
          withSwap,
          swapSize,
        }:
        if filesystem == "btrfs" then
          {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = helpers.mkBtrfsSubvolumes { inherit withSwap swapSize; };
          }
        else
          {
            type = "filesystem";
            format = "ext4";
            inherit mountpoint;
          };

      wrapEncryption =
        content:
        if encryptDrives then
          helpers.mkLuksWrapper {
            name = "crypt${name}";
            passwordFile = encryptionPasswordFile;
            inherit content;
          }
        else
          content;

      mkRootPartition = {
        size = "100%";
        content = wrapEncryption (mkFilesystemContent {
          inherit filesystem withSwap swapSize;
          mountpoint = mountPoint;
        });
      };

      mkRaidDisk = i: device: {
        "${name}_disk${toString i}" = {
          inherit device;
          type = "disk";
          content = {
            type = "gpt";
            partitions =
              (lib.optionalAttrs isOsDisk {
                "esp${toString i}" =
                  # Mount first ESP to /boot/efi, additional ones to /boot/efi-N
                  # GRUB's mirroredBoots will sync them
                  if i == 0 then
                    helpers.mkEspPartition
                  else
                    helpers.mkEspPartitionWithMount "/boot/efi-${toString i}";
              })
              // {
                raid = {
                  size = "100%";
                  content = {
                    type = "mdraid";
                    inherit name;
                  };
                };
              };
          };
        };
      };

      mkRaidArray = {
        ${name} = {
          type = "mdadm";
          level = raidLevel;
          content = {
            type = "gpt";
            partitions = {
              primary = mkRootPartition;
            };
          };
        };
      };
    in
    if isRaid then
      {
        disk = lib.foldl (acc: i: acc // (mkRaidDisk i (builtins.elemAt devices i))) { } (
          lib.range 0 ((builtins.length devices) - 1)
        );
        mdadm = mkRaidArray;
      }
    else
      {
        disk = {
          ${name} = {
            device = builtins.head devices;
            type = "disk";
            content = {
              type = "gpt";
              partitions =
                (lib.optionalAttrs isOsDisk {
                  esp = helpers.mkEspPartition;
                })
                // {
                  root = mkRootPartition;
                };
            };
          };
        };
        mdadm = { };
      };
}
