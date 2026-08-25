{
  flake.modules.nixos.fingerprint =
    { lib, ... }:
    {
      services.fprintd.enable = true;

      security.pam.services = {
        login.fprintAuth = true;
        sudo.fprintAuth = true;

        hyprlock = {
          fprintAuth = true;
          text = lib.mkForce ''
            auth     sufficient pam_fprintd.so
            auth     include    login
            account  include    login
            password include    login
            session  include    login
          '';
        };

        greetd.fprintAuth = true;

        "noctalia-shell" = {
          fprintAuth = true;
          text = lib.mkForce ''
            auth     sufficient pam_fprintd.so
            auth     include    login
            account  include    login
            password include    login
            session  include    login
          '';
        };
      };
    };

  flake.modules.homeManager.fingerprint =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.polkit_gnome ];

      programs.hyprlock.settings.auth.fingerprint.enabled = true;
    };
}
