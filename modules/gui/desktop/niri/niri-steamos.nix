{ config, self, ... }:
let
  inherit (config) theme;
  noctaliaShellModule = config.flake.wrapperModules.noctalia-shell;
  niriModule = config.flake.wrapperModules.niri;
in
{
  flake.wrappers.noctalia-shell-steamos =
    { lib, ... }:
    {
      imports = [ noctaliaShellModule ];
      settings.idle.enabled = lib.mkForce false;
    };

  flake.wrappers.niri-steamos =
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
          (lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia-shell-steamos)
        ];
      };
    };

  flake.modules.nixos.niri-steamos =
    { pkgs, lib, ... }:
    {
      programs.niri.package = lib.mkForce self.packages.${pkgs.stdenv.hostPlatform.system}.niri-steamos;
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia-shell-steamos
      ];

      systemd.user.services.lock-on-desktop-start = {
        description = "Lock noctalia-shell when entering desktop mode";
        unitConfig = {
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "lock-on-desktop-start" ''
            until ${
              lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia-shell-steamos
            } ipc call lockScreen lock 2>/dev/null; do
              sleep 0.5
            done
          '';
          TimeoutStartSec = "15";
        };
        wantedBy = [ "graphical-session.target" ];
      };
    };
}
