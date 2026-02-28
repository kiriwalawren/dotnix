{ config, ... }:
let
  inherit (config) theme;
in
{
  flake.modules.nixos.hyprland =
    { pkgs, lib, ... }:
    {
      programs = {
        hyprland = {
          enable = true;
          xwayland.enable = true;
        };
      };

      environment = {
        systemPackages = [ pkgs.brightnessctl ]; # For controllings screen brightness
        sessionVariables = {
          # Hint electron apps to use wayland
          NIXOS_OZONE_WL = "1";
        };
      };

      xdg.portal.extraPortals = [
        pkgs.xdg-desktop-portal-wlr # Screensharing
      ];

      hardware.graphics.enable = true;

      services = {
        xserver = {
          enable = true;

          # Configure keymap in X11
          xkb = {
            layout = "us";
            variant = "";
          };
        };

        dbus.enable = true;
      };
    };

  flake.modules.homeManager.hyprland =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      rgba = color: "rgba(${color}ee)";
      primaryAccent = rgba config.catppuccin.colors.primaryAccent;
      secondaryAccent = rgba config.catppuccin.colors.secondaryAccent;
      tertiaryAccent = rgba config.catppuccin.colors.tertiaryAccent;
      crust = rgba config.catppuccin.colors.crust;

      # binds $meh + [SUPER +] {1...8} to [move to] workspace {1...8} (stolen from sioodmy)
      workspaces = builtins.concatLists (
        builtins.genList (
          i:
          let
            workspace = builtins.toString (i + 1);
          in
          [
            "SUPER, ${workspace}, workspace, ${workspace}"
            "SHIFTSUPER, ${workspace}, movetoworkspace, ${workspace}"
          ]
        ) 8
      );
    in
    {
      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = true;

        settings = {
          input = {
            accel_profile = "adaptive";
            sensitivity = 0.4;
          };

          gesture = [ "3, horizontal, workspace" ];

          general = {
            gaps_in = 2;
            gaps_out = 2;
            border_size = 2;
            layout = "dwindle";
            "col.active_border" = "${primaryAccent} ${secondaryAccent} ${tertiaryAccent} 45deg";
            "col.inactive_border" = "${crust}";
          };

          misc = {
            disable_hyprland_logo = true;
            mouse_move_enables_dpms = true;
            key_press_enables_dpms = true;
          };

          ecosystem = {
            no_update_news = true;
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

          bind = [
            ",XF86MonBrightnessUp,exec,brightnessctl set +10%"
            ",XF86MonBrightnessDown,exec,brightnessctl set 10%-"
            "SUPER,Q,killactive"
            "SUPER,F, fullscreen"
            "SUPER,P,exec,${pkgs.hyprpicker}/bin/hyprpicker -a"

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
        };
      };
    };
}
