{
  lib,
  device ? "/dev/sda",
  efi ? true,
  withSwap ? false,
  swapSize ? 4,
  ...
}: let
  btrfsSubvolumes = {
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

  rootPartition = {
    size = "100%";
    content = {
      type = "btrfs";
      extraArgs = ["-f"];
      subvolumes = btrfsSubvolumes;
    };
  };

  espPartition = {
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

  biosBootPartition = {
    name = "BIOS-BOOT";
    start = "1M";
    end = "2M";
    type = "EF02"; # GRUB’s BIOS‑boot partition on GPT
  };

  partitions =
    if efi
    then {
      esp = espPartition;
      root = rootPartition;
    }
    else {
      bios = biosBootPartition;
      root = rootPartition;
    };
in {
  disko.devices.disk.main = {
    inherit device;
    type = "disk";
    content = {
      type = "gpt";
      inherit partitions;
    };
  };
}
