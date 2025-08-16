{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.ui.hyprland;
in {
  meta.doc = lib.mdDoc ''
    Hyprland Wayland compositor with complete desktop environment setup.

    Configures [Hyprland](https://hyprland.org/) with:
    - SDDM display manager with Wayland support
    - XDG desktop portals for screen sharing and file dialogs
    - Hardware graphics acceleration
    - GNOME Keyring integration
    - PAM configuration for hyprlock
    - Increased file descriptor limits for wheel group
  '';

  options.ui.hyprland = {
    enable = mkEnableOption (lib.mdDoc "Hyprland Wayland compositor");
  };

  config = mkIf cfg.enable {
    programs = {
      hyprland = {
        enable = true;
        xwayland.enable = true;
      };
    };

    environment.sessionVariables = {
      # Hint electron apps to use wayland
      NIXOS_OZONE_WL = "1";
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
      displayManager.sddm = {
        enable = true; # Display manager, initial login screen
        wayland.enable = true;
      };

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
