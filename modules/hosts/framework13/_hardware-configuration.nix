{ inputs, ... }:
{
  imports = [ inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series ];

  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  boot = {
    kernelModules = [
      "i2c_hid"
      "i2c_hid_acpi"
      "hid_generic"
      "hid_multitouch"
    ];
  };

  services.fwupd.enable = true;
}
