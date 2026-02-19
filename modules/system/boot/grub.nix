{
  flake.modules.nixos.base =
    {
      config,
      lib,
      ...
    }:
    let
      rootDiskGroup = config.system.disks."/" or null;
      hasRaidRoot = rootDiskGroup != null && rootDiskGroup.raidLevel != null;

      # Generate mirroredBoots entries for each device in RAID
      # First device uses /boot/efi, others use /boot/efi-N
      mirroredBootsForRaid =
        if hasRaidRoot then
          lib.imap0 (i: _dev: {
            devices = [ "nodev" ];
            path = if i == 0 then "/boot/efi" else "/boot/efi-${toString i}";
          }) rootDiskGroup.devices
        else
          [ ];
    in
    {
      catppuccin.grub.enable = true;

      boot.loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot/efi";
        };
        grub = {
          efiSupport = true;
          device = "nodev";
        }
        // (lib.optionalAttrs hasRaidRoot {
          # For UEFI RAID boot, only use mirroredBoots (not devices)
          # Setting devices would trigger legacy BIOS installation
          mirroredBoots = mirroredBootsForRaid;
        });
      };
    };
}
