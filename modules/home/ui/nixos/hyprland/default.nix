{
  pkgs,
  lib,
  config,
  theme,
  ...
}:
with lib; let
  cfg = config.ui.nixos.hyprland;

  pamixer = "${pkgs.pamixer}/bin/pamixer";
  playerctl = "${pkgs.playerctl}/bin/playerctl";

  rgba = color: "rgba(${color}ee)";
  primaryAccent = rgba theme.colors.primaryAccent;
  secondaryAccent = rgba theme.colors.secondaryAccent;
  tertiaryAccent = rgba theme.colors.tertiaryAccent;
  crust = rgba theme.colors.crust;

  # binds $meh + [SUPER +] {1...8} to [move to] workspace {1...8} (stolen from sioodmy)
  workspaces = builtins.concatLists (
    builtins.genList
    (
      i: let
        workspace = builtins.toString (i + 1);
      in [
        "SUPER, ${workspace}, workspace, ${workspace}"
        "SHIFTSUPER, ${workspace}, movetoworkspace, ${workspace}"
      ]
    )
    8
  );
in {
  imports = [
    ./grimblast.nix
    ./hyprlock.nix
    ./hypridle.nix
    ./hyprpaper.nix
  ];

  options.ui.nixos.hyprland = {enable = mkEnableOption "hyprland";};

  config = mkIf cfg.enable {
    ui.nixos.hyprland = {
      grimblast.enable = true; # Screenshot utility
      hypridle.enable = true; # Idle daemon
      hyprlock.enable = true; # Lock screen
      hyprpaper.enable = true; # Configures wallpaper
    };

    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;

      settings = {
        input = {
          accel_profile = "adaptive";
          sensitivity = 0.4;
        };

        gesture = ["3, horizontal, workspace"];

        general = {
          gaps_in = 2;
          gaps_out = 5;
          border_size = 3;
          layout = "dwindle";
          "col.active_border" = "${primaryAccent} ${secondaryAccent} ${tertiaryAccent} 45deg";
          "col.inactive_border" = "${crust}";
        };

        misc = {
          disable_hyprland_logo = true;
          mouse_move_enables_dpms = true;
          key_press_enables_dpms = true;
        };

        decoration = {
          rounding = theme.radius;

          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
          };
        };

        animations = {
          enabled = true;
          bezier = [
            "linear,0.0,0.0,1.0,1.0"
          ];
          animation = [
            "borderangle,1,100,linear,loop"
          ];
        };

        dwindle = {
          preserve_split = "yes";
        };

        windowrulev2 = [
          "float,class:(wiremix)"
          "center,class:(wiremix)"
          "size 800 600,class:(wiremix)"
          "stayfocused,class:(wiremix)"

          "float,class:(impala)"
          "center,class:(impala)"
          "size 800 700,class:(impala)"
          "stayfocused,class:(impala)"
        ];

        bind =
          [
            ",XF86MonBrightnessUp,exec,brightnessctl set +10%"
            ",XF86MonBrightnessDown,exec,brightnessctl set 10%-"
            "SUPER,Q,killactive"
            "SUPER,F, fullscreen"

            "SUPER,H,movefocus,l"
            "SUPER,L,movefocus,r"
            "SUPER,K,movefocus,u"
            "SUPER,J,movefocus,d"

            "SHIFTSUPER,H,movewindow,l"
            "SHIFTSUPER,L,movewindow,r"
            "SHIFTSUPER,K,movewindow,u"
            "SHIFTSUPER,J,movewindow,d"
          ]
          ++ workspaces;

        bindm = [
          "SUPER,mouse:272,movewindow"
          "SUPER,mouse:273,resizewindow"
        ];

        binde = [
          ",XF86AudioRaiseVolume,exec,${pamixer} -i 5"
          ",XF86AudioLowerVolume,exec,${pamixer} -d 5"
          ",XF86AudioMute,exec,${pamixer} -t"
          ",XF86AudioMicMute,exec,micmute"
        ];

        bindl = [
          ",XF86AudioPlay,exec,${playerctl} play-pause"
          ",XF86AudioPrev,exec,${playerctl} previous"
          ",XF86AudioNext,exec,${playerctl} next"
        ];
      };
    };
  };
}
