{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.ui.fingerprint;
in
{
  options.ui.fingerprint = {
    enable = mkEnableOption "fingerprint";
  };

  config = mkIf cfg.enable {
    services.fprintd.enable = true;

    security.pam.services = {
      login.fprintAuth = true;
      sudo.fprintAuth = true;

      hyprlock = {
        fprintAuth = fingerprint.enable;
        text = mkForce ''
          auth     sufficient pam_fprintd.so
          auth     include    login
          account  include    login
          password include    login
          session  include    login
        '';
      };
    };
  };
}
