{
  config,
  inputs,
  lib,
  ...
}:
let
  user = config.user.name;
in
{
  nixpkgs.config.allowUnfreePackages = [
    "steamdeck-hw-theme"
    "steam-jupiter-unwrapped"
  ];

  flake.modules.nixos.steamos = { config, ... }: {
    imports = [ inputs.jovian.nixosModules.jovian ];

    jovian.steam = {
      inherit user;
      enable = true;
      autoStart = true;

      desktopSession =
        if config.programs.niri.enable or false then
          "niri"
        else if config.programs.hyprland.enable or false then
          "hyprland"
        else
          "gamescope-wayland";
    };

    services.greetd.enable = lib.mkForce false;
  };
}
