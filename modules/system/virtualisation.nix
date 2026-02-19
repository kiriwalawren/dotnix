{ config, ... }:
let
  user = config.user.name;
in
{
  flake.modules.nixos.virtualisation =
    { pkgs, ... }:
    {
      virtualisation = {
        libvirtd = {
          enable = true;
          qemu = {
            package = pkgs.qemu_kvm;

            # Software TPM emulation
            swtpm.enable = true;
          };
        };
      };

      programs.virt-manager.enable = true;

      users.extraGroups.libvirt.members = [ user ];

      environment.systemPackages = with pkgs; [
        swtpm
        libtpms
        OVMFFull
      ];
    };
}
