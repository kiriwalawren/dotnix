{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.system.cachix;
in
{
  options.system.cachix = {
    enable = mkEnableOption "cachix";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cachix
    ];

    nix = {
      settings = {
        trusted-users = [
          "root"
          config.user.name
        ];

        substituters = [
          "https://cache.nixos.org"
          "https://kiriwalawren.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "kiriwalawren.cachix.org-1:a4EdChIG5Si1mIBrWfXn1g4ikinyO2jyycgwEds9eBQ="
        ];
      };
    };
  };
}
