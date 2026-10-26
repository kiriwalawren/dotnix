{
  flake.modules.nixos.encryption = { pkgs, ... }: {
    # Add packages for Secure Boot and TPM2 management
    environment.systemPackages = with pkgs; [
      sbctl # Secure Boot key management
      tpm2-tools # TPM2 diagnostics and management
      cryptsetup # LUKS operations
    ];

    boot.initrd = {
      # Enable TPM2 support in initrd
      systemd.tpm2.enable = true;

      # Add TPM kernel modules
      availableKernelModules = [
        "tpm_tis"
        "tpm_crb"
      ];
    };
  };
}
