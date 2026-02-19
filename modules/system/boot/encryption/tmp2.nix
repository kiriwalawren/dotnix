{
  flake.modules.nixos.encryption =
    { pkgs, ... }:
    {
      initrd = {
        # Enable systemd in initrd for TPM2 auto-unlock support
        systemd = {
          enable = true;
          # Enable TPM2 support in initrd
          tpm2.enable = true;
        };

        # Add TPM kernel modules
        availableKernelModules = [
          "tpm_tis"
          "tpm_crb"
        ];
      };

      # Add packages for Secure Boot and TPM2 management
      environment.systemPackages = with pkgs; [
        sbctl # Secure Boot key management
        tpm2-tools # TPM2 diagnostics and management
        cryptsetup # LUKS operations
      ];
    };
}
