{
  flake.modules.nixos.gui =
    { pkgs, ... }:
    {
      services.udisks2.enable = true;
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="block", ENV{ID_FS_TYPE}!="", RUN+="${pkgs.systemd}/bin/systemd-run --user --machine=1000@ ${pkgs.libnotify}/bin/notify-send 'SD Card Inserted' 'Device: $devnode'"
      '';
    };

  flake.modules.homeManager.gui =
    { pkgs, lib, ... }:
    {
      programs.niri.settings.spawn-at-startup = [
        {
          command = [
            (lib.getExe pkgs.udiskie)
            "--notify"
          ];
        }
      ];

      wayland.windowManager.hyprland.settings = {
        "exec-once" = [
          "${lib.getExe pkgs.udiskie}"
          "--notify"
        ];
      };
    };
}
