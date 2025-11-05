{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.system.encryption.tpm2;
in {
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  options.system.encryption.tpm2 = {
    enable = mkEnableOption "Full-disk encryption with TPM2 and Secure Boot support";
  };

  config = mkIf cfg.enable {
    boot = {
      loader = {
        # Forcefully disable grub (incompatible with lanzaboote)
        grub.enable = mkForce false;

        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot/efi";
        };
        # Use systemd-boot when lanzaboote is disabled, lanzaboote when keys exist
        systemd-boot.enable = mkForce (!config.boot.lanzaboote.enable);
      };

      # Boot loader configuration
      # Lanzaboote auto-enables when Secure Boot keys exist at /var/lib/sbctl/keys/
      # This allows the bootstrap script to generate keys, triggering automatic
      # lanzaboote enablement on the next rebuild without manual config edits.
      lanzaboote = {
        enable = builtins.pathExists "/var/lib/sbctl/keys/db/db.key";
        pkiBundle = "/var/lib/sbctl";
      };

      initrd = {
        # Enable systemd in initrd for TPM2 auto-unlock support
        systemd = {
          enable = true;
          # Enable TPM2 support in initrd
          tpm2.enable = true;
        };

        # Add TPM kernel modules
        availableKernelModules = ["tpm_tis" "tpm_crb"];
      };
    };

    # Add packages for Secure Boot and TPM2 management
    environment.systemPackages = with pkgs; [
      sbctl # Secure Boot key management
      tpm2-tools # TPM2 diagnostics and management
      cryptsetup # LUKS operations
    ];
  };
}
