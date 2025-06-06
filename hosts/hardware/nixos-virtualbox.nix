# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{lib, ...}: {
  imports = [];

  boot = {
    initrd = {
      availableKernelModules = ["ata_piix" "ohci_pci" "ehci_pci" "ahci" "sd_mod" "sr_mod"];
      kernelModules = [];
    };

    kernelModules = [];
    extraModulePackages = [];
  };

  networking.useDHCP = lib.mkDefault true;
  virtualisation.virtualbox.guest.enable = true;
}
