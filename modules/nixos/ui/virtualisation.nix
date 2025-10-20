{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ui.virtualisation;
in {
  options.ui.virtualisation = {enable = mkEnableOption "virtualisation";};

  config = mkIf cfg.enable {
    virtualisation = {
      libvirtd = {
        enable = true;
        qemu.package = pkgs.qemu_kvm;
      };
    };
    programs.virt-manager.enable = true;

    users.extraGroups.libvirt.members = [config.user.name];
  };
}
