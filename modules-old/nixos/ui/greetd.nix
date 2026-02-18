{
  pkgs,
  lib,
  config,
  theme,
  ...
}:
with lib;
let
  cfg = config.ui.greetd;
in
{
  options.ui.greetd = {
    enable = mkEnableOption "greetd";
  };

  config = mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --asterisks --cmd Hyprland";
          user = "greeter";
        };
      };
    };

    # Configure available desktop sessions
    environment.etc."greetd/environments".text = ''
      Hyprland
    '';

    # Configure TTY colors to match Catppuccin theme
    # These colors will style the tuigreet interface
    console = {
      colors = [
        theme.colors.surface0 # black
        theme.colors.red # red
        theme.colors.green # green
        theme.colors.yellow # yellow
        theme.colors.blue # blue
        theme.colors.mauve # magenta
        theme.colors.teal # cyan
        theme.colors.text # white
        theme.colors.overlay0 # bright black
        theme.colors.red # bright red
        theme.colors.green # bright green
        theme.colors.yellow # bright yellow
        theme.colors.blue # bright blue
        theme.colors.mauve # bright magenta
        theme.colors.teal # bright cyan
        theme.colors.text # bright white
      ];
    };

    # Ensure gnome-keyring and fingerprint work with greetd
    security.pam.services.greetd = {
      enableGnomeKeyring = true;
      fprintAuth = config.ui.fingerprint.enable;
    };
  };
}
