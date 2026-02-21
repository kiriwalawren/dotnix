{
  flake.modules.nixos.gui =
    { pkgs, ... }:
    {
      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --asterisks --cmd Hyprland --theme 'border=magenta;text=white;prompt=cyan;time=blue;action=green;button=green;container=black;input=white'";
            user = "greeter";
          };
        };
      };

      # Without this, tuigreet renders before the palette is loaded.
      console.earlySetup = true;

      # Configure available desktop sessions
      environment.etc."greetd/environments".text = ''
        Hyprland
      '';

      # Ensure gnome-keyring greetd
      security.pam.services.greetd = {
        enableGnomeKeyring = true;
      };
    };
}
