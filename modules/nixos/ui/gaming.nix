{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.ui.gaming;
in {
  meta.doc = lib.mdDoc ''
    Gaming configuration for NixOS.

    Provides a comprehensive gaming setup including:
    - [Steam](https://store.steampowered.com/about/) with Proton support
    - [Heroic Games Launcher](https://heroicgameslauncher.com/) for Epic/GOG games
    - [ProtonUp](https://github.com/AUNaseef/protonup) for Proton version management
    - [MangoHud](https://github.com/flightlessmango/MangoHud) for performance monitoring
    - [GameMode](https://github.com/FeralInteractive/gamemode) for performance optimization
    - GameScope session support for improved gaming experience
  '';

  options.ui.gaming = {
    enable = mkEnableOption (lib.mdDoc "gaming support with Steam, Heroic, and performance tools");
  };

  config = mkIf cfg.enable {
    programs.steam = {
      enable = true;
      gamescopeSession.enable = true;
      remotePlay.openFirewall = true;
    };

    environment.systemPackages = with pkgs; [
      heroic
      mangohud
      protonup
    ];

    programs.gamemode.enable = true;

    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATH = "/home/${config.user.name}/.steam/root/compatibilitytools.d";
    };
  };
}
