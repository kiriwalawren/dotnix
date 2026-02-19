{ config, inputs, ... }:
let
  user = config.user.name;
in
{
  flake.modules.nixos.nixflix =
    { config, ... }:
    {
      imports = [
        inputs.nixflix.nixosModules.default
      ];

      nixflix = {
        enable = true;
        mediaUsers = [ user ];

        theme = {
          enable = true;
          name = "catppuccin-${config.catppuccin.flavor}";
        };

        nginx = {
          enable = true;
          addHostsEntries = false;
          domain = "nixflix";
        };

        postgres.enable = true;

        recyclarr = {
          enable = true;
          cleanupUnmanagedProfiles = true;
        };
      };
    };
}
