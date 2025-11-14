{
  lib,
  device ? "/dev/sda",
  raidDevice1 ? "/dev/sdb",
  raidDevice2 ? "/dev/sdc",
  withSwap ? false,
  swapSize ? 4,
  encryptDrives ? false,
  encryptionPasswordFile ? "/tmp/disk-secret.key",
  ...
}: {
  disko.devices = {
    disk = {
      # Main OS disk
      main = {
        inherit device;

        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efi";
                mountOptions = ["defaults"];
              };
            };
            root = {
              size = "100%";
              content =
                if encryptDrives
                then {
                  type = "luks";
                  name = "cryptroot";
                  settings = {
                    allowDiscards = true;
                  };
                  passwordFile = encryptionPasswordFile;
                  content = {
                    type = "btrfs";
                    extraArgs = ["-f"]; # Override existing partition
                    # Subvolumes must set a mountpoint in order to be mounted,
                    # unless their parent is mounted
                    subvolumes = {
                      "/root" = {
                        mountpoint = "/";
                        mountOptions = ["compress=zstd" "noatime"];
                      };
                      "/nix" = {
                        mountpoint = "/nix";
                        mountOptions = ["compress=zstd" "noatime"];
                      };
                      "/swap" = lib.mkIf withSwap {
                        mountpoint = "/.swapvol";
                        swap.swapfile.size = "${swapSize}G";
                      };
                    };
                  };
                }
                else {
                  type = "btrfs";
                  extraArgs = ["-f"]; # Override existing partition
                  # Subvolumes must set a mountpoint in order to be mounted,
                  # unless their parent is mounted
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "/swap" = lib.mkIf withSwap {
                      mountpoint = "/.swapvol";
                      swap.swapfile.size = "${swapSize}G";
                    };
                  };
                };
            };
          };
        };
      };

      # First RAID disk
      raid1 = {
        device = raidDevice1;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            raid = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "raid1";
              };
            };
          };
        };
      };

      # Second RAID disk
      raid2 = {
        device = raidDevice2;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            raid = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "raid1";
              };
            };
          };
        };
      };
    };

    # RAID 1 array configuration
    mdadm = {
      raid1 = {
        type = "mdadm";
        level = 1;
        content = {
          type = "gpt";
          partitions = {
            primary = {
              size = "100%";
              content =
                if encryptDrives
                then {
                  type = "luks";
                  name = "cryptraid";
                  settings = {
                    allowDiscards = true;
                  };
                  passwordFile = encryptionPasswordFile;
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountpoint = "/data";
                  };
                }
                else {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/data";
                };
            };
          };
        };
      };
    };
  };
}
