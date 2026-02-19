{ inputs, ... }:
{
  flake.modules.nixos.encryption =
    { config, lib, ... }:
    {
      imports = [
        inputs.lanzaboote.nixosModules.lanzaboote
      ];

      boot = {
        loader = {
          # Forcefully disable grub (incompatible with lanzaboote)
          grub.enable = lib.mkForce false;

          efi = {
            canTouchEfiVariables = true;
            efiSysMountPoint = "/boot/efi";
          };
          # Use systemd-boot when lanzaboote is disabled, lanzaboote when keys exist
          systemd-boot.enable = lib.mkForce (!config.boot.lanzaboote.enable);
        };

        # Boot loader configuration
        # Lanzaboote is enabled by default for Secure Boot support.
        # During initial install, the bootstrap script uses a temporary flake that
        # overrides this to false (before keys exist), then subsequent rebuilds
        # use the real configuration with lanzaboote enabled.
        lanzaboote = {
          enable = lib.mkDefault true;
          pkiBundle = "/var/lib/sbctl";
        };
      };
    };
}
