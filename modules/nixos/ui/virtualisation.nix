{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.ui.virtualisation;
in {
  options.ui.virtualisation = {enable = mkEnableOption "virtualisation";};

  config = mkIf cfg.enable {
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;

    users.extraGroups.libvirt.members = [config.user.name];
  };
}
