{ config, inputs, ... }:
let
  user = config.user.name;
in
{
  flake.modules.nixos.nixflix = {
    imports = [
      inputs.nixflix.nixosModules.default
    ];

    nixflix = {
      enable = true;
      mediaUsers = [ user ];

      # TODO: theming
      # theme = {
      #   enable = true;
      #   name = "catppuccin-${theme.variant}";
      # };

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
