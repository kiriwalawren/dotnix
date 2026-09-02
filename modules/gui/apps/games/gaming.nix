{
  nixpkgs.config.allowUnfreePackages = [
    "steam"
    "steam-unwrapped"
  ];

  flake.modules.nixos.gaming =
    { config, pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        gamescopeSession.enable = true;
        remotePlay.openFirewall = true;
      };

      environment.systemPackages = with pkgs; [
        heroic
        mangohud
        protonup-rs
        sgdboop
        (bottles.override { removeWarningPopup = true; })
      ];

      programs.gamemode.enable = true;

      environment.sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATH = "/home/${config.user.name}/.steam/root/compatibilitytools.d";
      };

      systemd.services.protonup-rs = {
        description = "Update GE-Proton for Steam";
        serviceConfig = {
          Type = "oneshot";
          User = config.user.name;
          ExecStart = "${pkgs.protonup-rs}/bin/protonup-rs -q";
        };
      };

      systemd.timers.protonup-rs = {
        description = "Daily GE-Proton update timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
    };
}
