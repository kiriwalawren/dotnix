{
  flake.modules.nixos.fingerprint = {
    services.fprintd.enable = true;

    security.pam.services = {
      login.fprintAuth = true;
      sudo.fprintAuth = true;
      greetd.fprintAuth = true;
    };
  };

  flake.modules.homeManager.fingerprint = { pkgs, ... }: { home.packages = [ pkgs.polkit_gnome ]; };
}
