{
  flake.modules.nixos.gui =
    {
      config,
      pkgs,
      ...
    }:
    {
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
        colors = with config.catppuccin.colors; [
          surface0
          red
          green
          yellow
          blue
          mauve
          teal
          text
          overlay0
          red
          green
          yellow
          blue
          mauve
          teal
          text
        ];
      };

      # Ensure gnome-keyring greetd
      security.pam.services.greetd = {
        enableGnomeKeyring = true;
      };
    };
}
