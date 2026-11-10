{ config, self, ... }:
let
  inherit (config) theme;
  noctaliaModule = config.flake.wrapperModules.noctalia;
  niriModule = config.flake.wrapperModules.niri;
in
{
  flake.wrappers.noctalia-steamos = { lib, ... }: {
    imports = [ noctaliaModule ];
    settings.idle.behavior = {
      screen-off.enabled = lib.mkForce false;
      lock.enabled = lib.mkForce false;
      lock-and-suspend.enabled = lib.mkForce false;
    };
    settings.bar.default = {
      thickness = lib.mkForce 32;
      scale = lib.mkForce 1.0;
    };
  };

  flake.wrappers.niri-steamos = { lib, pkgs, ... }: {
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
        (lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia-steamos)
      ];
    };
  };

  flake.modules.nixos.niri-steamos = { pkgs, lib, ... }: {
    programs.niri.package = lib.mkForce self.packages.${pkgs.stdenv.hostPlatform.system}.niri-steamos;
    environment.systemPackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia-steamos ];

    systemd.user.services.lock-on-desktop-start = {
      description = "Lock noctalia when entering desktop mode";
      unitConfig = {
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "lock-on-desktop-start" ''
          until ${
            lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia-steamos
          } msg session lock 2>/dev/null; do
            sleep 0.5
          done
        '';
        TimeoutStartSec = "15";
      };
      wantedBy = [ "graphical-session.target" ];
    };
  };
}
