{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.ui.virtualisation;
in
{
  options.ui.virtualisation = {
    enable = mkEnableOption "virtualisation";
  };

  config = mkIf cfg.enable {
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

    users.extraGroups.libvirt.members = [ config.user.name ];

    environment.systemPackages = with pkgs; [
      swtpm
      libtpms
      OVMFFull
    ];
  };
}
