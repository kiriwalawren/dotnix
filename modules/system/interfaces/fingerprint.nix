{
  flake.modules.nixos.fingerprint =
    { lib, ... }:
    {
      services.fprintd.enable = true;

      # Prevent Goodix MOC fingerprint sensor from going into USB autosuspend.
      # Without this, the device becomes unavailable to fprintd after the screen
      # turns off, causing pam_fprintd.so to fail immediately on auto-lock and
      # fall through to password-only auth.
      services.udev.extraRules = ''
        SUBSYSTEM=="usb", ATTR{idVendor}=="27c6", ATTR{idProduct}=="609c", ATTR{power/control}="on"
      '';

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

      wayland.windowManager.hyprland.settings = {
        exec-once = [ "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" ];
      };
      programs.hyprlock.settings.auth.fingerprint.enabled = true;
    };
}
