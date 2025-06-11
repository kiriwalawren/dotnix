{
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.system.bootloader;
in {
  options.system.bootloader = {
    efi = mkOption {
      type = types.bool;
      default = true;
      description = "Whether the system uses UEFI (true) or Legacy BIOS (false).";
    };
  };

  config = lib.mkIf (!config.wsl.enable) {
    catppuccin.grub.enable = true;
    boot.loader = {
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = cfg.efi;
        efiInstallAsRemovable = lib.mkIf cfg.efi (!config.boot.loader.efi.canTouchEfiVariables);
      };

      efi = lib.mkIf cfg.efi {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };
  };
}
