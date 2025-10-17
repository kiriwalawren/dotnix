{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.ui.virtualbox;
in {
  options.ui.virtualbox = {enable = mkEnableOption "virtualbox";};

  config = mkIf cfg.enable {
    virtualisation.virtualbox.host.enable = true;
    virtualisation.virtualbox.host.enableExtensionPack = true;

    users.extraGroups.vboxusers.members = [config.user.name];
  };
}
