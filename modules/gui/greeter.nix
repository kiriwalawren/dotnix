{
  flake.modules.nixos.gui =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      options.services.greetd.cmd = lib.mkOption {
        type = lib.types.enum [
          "Hyprland"
          "niri"
        ];
        default = null;
      };

      config = {
        services.greetd = {
          enable = true;
          settings = {
            default_session = {
              command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --asterisks --cmd ${config.services.greetd.cmd} --theme 'border=magenta;text=white;prompt=cyan;time=blue;action=green;button=green;container=black;input=white'";
              user = "greeter";
            };
          };
        };

        # Without this, tuigreet renders before the palette is loaded.
        console.earlySetup = true;

        # Configure available desktop sessions
        environment.etc."greetd/environments".text = ''
          ${config.services.greetd.cmd}
        '';

        # Ensure gnome-keyring greetd
        security.pam.services.greetd = {
          enableGnomeKeyring = true;
        };
      };
    };
}
