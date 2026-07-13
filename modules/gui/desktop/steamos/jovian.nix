{ config, inputs, ... }:
let
  user = config.user.name;
in
{
  nixpkgs.config.allowUnfreePackages = [
    "steamdeck-hw-theme"
    "steam-jupiter-unwrapped"
  ];

  flake.modules.nixos.steamos = {
    imports = [ inputs.jovian.nixosModules.jovian ];

    jovian.steam = {
      inherit user;
      enable = true;
      autoStart = true;

      desktopSession = "gamescope-wayland"; # TODO: change this to niri
    };
  };
}
