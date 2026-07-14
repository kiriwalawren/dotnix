{ config, self, ... }:
let
  inherit (config) theme;
  noctaliaShellModule = config.flake.wrapperModules.noctalia-shell;
  niriModule = config.flake.wrapperModules.niri;
in
{
  flake.wrappers.noctalia-shell-homelab =
    { lib, ... }:
    {
      imports = [ noctaliaShellModule ];
      settings.idle.enable = lib.mkForce false;
    };

  flake.wrappers.niri-homelab =
    { lib, pkgs, ... }:
    {
      imports = [ niriModule ];
      settings = {
        window-rules = lib.mkForce [
          {
            geometry-corner-radius = theme.radius;
            clip-to-geometry = true;
          }
        ];
        spawn-at-startup = lib.mkForce [
          "systemctl"
          "--user"
          "import-environment"
          "WAYLAND_DISPLAY"
          "XDG_SESSION_TYPE"
          "env"
          "NOCTALIA_PAM_SERVICE=noctalia-shell"
          (lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia-shell-homelab)
        ];
      };
    };

  flake.modules.nixos.niri-homelab =
    { pkgs, lib, ... }:
    {
      programs.niri.package = lib.mkForce self.packages.${pkgs.stdenv.hostPlatform.system}.niri-homelab;
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia-shell-homelab
      ];
    };
}
