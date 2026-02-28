{ config, ... }:
let
  user = config.user.name;
in
{
  flake.modules.nixos.sound = {
    users.users.${user}.extraGroups = [
      "audio"
      "sound"
    ];

    programs.noisetorch.enable = true; # Mic Noise Filter

    security.rtkit.enable = true;
    services = {
      pulseaudio.support32Bit = true;
      pipewire = {
        enable = true;

        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
      };
    };
  };

  flake.modules.homeManager.sound =
    { lib, pkgs, ... }:
    let
      pamixer = "${lib.getExe pkgs.pamixer}";
      playerctl = "${lib.getExe pkgs.playerctl}";

      unmutemic = pkgs.writeShellScriptBin "unmutemic" ''
        ${pamixer} --list-sources | tail -n +2 | awk '{print $1}' | while read -r source; do
          ${pamixer} -u --source "$source"
        done
      '';

      mutemic = pkgs.writeShellScriptBin "mutemic" ''
        ${pamixer} --list-sources | tail -n +2 | awk '{print $1}' | while read -r source; do
          ${pamixer} -m --source "$source"
        done
      '';

      togglemic = pkgs.writeShellScriptBin "togglemic" ''
        ${pamixer} --list-sources | tail -n +2 | awk '{print $1}' | while read -r source; do
          ${pamixer} -t --source "$source"
        done
      '';
    in
    {
      home.packages = [
        unmutemic
        mutemic
        togglemic
        pkgs.wiremix
      ];

      # Waybar integration - override the pulseaudio on-click
      programs.waybar.settings.mainBar.pulseaudio.on-click =
        "pkill wiremix || ${lib.getExe pkgs.kitty} --class=wiremix ${lib.getExe pkgs.wiremix}";

      programs.niri.settings.window-rules = [
        {
          matches = [ { app-id = "wiremix"; } ];
          open-floating = true;
          default-column-width.fixed = 750;
          default-window-height.fixed = 700;
          opacity = 1.0;
        }
      ];

      wayland.windowManager.hyprland.settings = {
        windowrule = [
          "match:class wiremix, float on, center on, size 750 700, pin on, stay_focused on"
        ];

        bind = [
          ",XF86AudioMute,exec,${pamixer} -t"
          ",XF86AudioMicMute,exec,${togglemic}/bin/togglemic"

          "CTRL,Space,exec,${unmutemic}/bin/unmutemic"
        ];

        # Executes when key is released
        bindr = [
          "CTRL,Space,exec,${mutemic}/bin/mutemic"
        ];

        # Repeats when held
        binde = [
          ",XF86AudioRaiseVolume,exec,${pamixer} -i 5"
          ",XF86AudioLowerVolume,exec,${pamixer} -d 5"
        ];

        # Will also work when an input inhibitor (e.g. a lockscreen) is active
        bindl = [
          ",XF86AudioPlay,exec,${playerctl} play-pause"
          ",XF86AudioPrev,exec,${playerctl} previous"
          ",XF86AudioNext,exec,${playerctl} next"
        ];

        "exec-once" = [
          "${mutemic}/bin/mutemic"
        ];
      };
    };
}
