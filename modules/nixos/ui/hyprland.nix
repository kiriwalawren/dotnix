{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.ui.hyprland;
in {
  options.ui.hyprland = {enable = mkEnableOption "hyprland";};

  config = mkIf cfg.enable {
    programs = {
      hyprland = {
        enable = true;
        xwayland.enable = true;
      };
    };

    environment = {
      systemPackages = [pkgs.brightnessctl]; # For controllings screen brightness
      sessionVariables = {
        # Hint electron apps to use wayland
        NIXOS_OZONE_WL = "1";
      };
    };

    hardware.graphics.enable = true;

    xdg = {
      autostart.enable = true;
      portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-wlr # Screensharing
          xdg-desktop-portal-gtk
          xdg-desktop-portal-hyprland
        ];
      };
    };

    services = {
      xserver = {
        enable = true;

        # Configure keymap in X11
        xkb = {
          layout = "us";
          variant = "";
        };
      };

      gnome.gnome-keyring.enable = true;

      dbus.enable = true;
    };

    security.pam = {
      services = {
        hyprlock.text = " auth include login ";
        login.enableGnomeKeyring = true;
      };

      loginLimits = [
        {
          domain = "@wheel";
          item = "nofile";
          type = "soft";
          value = "524288";
        }
        {
          domain = "@wheel";
          item = "nofile";
          type = "hard";
          value = "1048576";
        }
      ];
    };
  };
}
