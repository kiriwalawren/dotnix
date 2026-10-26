{ self, ... }: {
  flake.modules.nixos.niri = { pkgs, ... }: {
    environment.systemPackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia ];
    services.upower.enable = true;
  };

  flake.wrappers.niri = { lib, pkgs, ... }: {
    settings = {
      debug.honor-xdg-activation-with-invalid-serial = [ ];

      spawn-at-startup = [ (lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia) ];
    };
  };

  flake.wrappers.noctalia =
    {
      config,
      lib,
      wlib,
      pkgs,
      ...
    }:
    {
      imports = [ wlib.modules.default ];

      options.settings = lib.mkOption {
        inherit ((pkgs.formats.toml { })) type;
        default = { };
        description = "Noctalia v5 configuration, written to config.toml.";
      };

      config = {
        package = lib.mkDefault pkgs.noctalia;
        env.NOCTALIA_CONFIG_HOME = "${placeholder config.outputName}/noctalia-config";
        passthru.generatedConfig = "${
          config.wrapper.${config.outputName}
        }/noctalia-config/noctalia/config.toml";

        constructFiles.config = {
          relPath = "noctalia-config/noctalia/config.toml";
          content = builtins.toJSON config.settings;
          # `config validate` only warns on unknown keys, so fail on any warning other than
          # plugin ones (plugins are fetched at runtime and can't be resolved here).
          builder = ''
            ${pkgs.remarshal}/bin/json2toml "$1" "$2"
            report="$(HOME="$(mktemp -d)" ${lib.getExe config.package} config validate "$2" 2>&1)" || {
              echo "$report"
              exit 1
            }
            unexpected="$(echo "$report" | grep '^WARN' \
              | grep -v 'unrecognized widget type "[^"]*/[^"]*:' \
              | grep -v 'no loaded plugin with this id' || true)"
            if [ -n "$unexpected" ]; then
              echo "$unexpected"
              exit 1
            fi
          '';
        };

        settings = {
          shell = {
            font_family = "Sans Serif";
            card_borders = false;
            telemetry_enabled = false;
            polkit_agent = true;
          };

          location = {
            address = "New York City";
            auto_locate = true;
            custom_schedule = false;
            sunrise = "06:30";
            sunset = "18:30";
          };

          weather = {
            enabled = true;
            effects = true;
            unit = "imperial";
          };

          control_center.calendar = {
            show_week_numbers = false;
            show_events_card = true;
          };

          system.monitor = {
            cpu_usage_activity_threshold = 80.0;
            cpu_usage_critical_threshold = 90.0;
            cpu_temp_activity_threshold = 80.0;
            cpu_temp_critical_threshold = 90.0;
            gpu_temp_activity_threshold = 80.0;
            gpu_temp_critical_threshold = 90.0;
            ram_pct_activity_threshold = 80.0;
            ram_pct_critical_threshold = 90.0;
            swap_pct_activity_threshold = 80.0;
            swap_pct_critical_threshold = 90.0;
            disk_used_pct_activity_threshold = 80.0;
            disk_used_pct_critical_threshold = 90.0;
          };

          battery.warning_threshold = 20;

          dock.enabled = false;

          osd = {
            enabled = true;
            position = "top_right";
            hide_delay_ms = 2000;
            background_opacity = 0.85;
            monitors = [ ];
            # v4 enabledTypes = [ Volume InputVolume Brightness ]; LockKey was off and v4
            # had no OSD for the other kinds, so they are off too.
            kinds = {
              volume = true;
              volume_input = true;
              volume_output = true;
              brightness = true;
              lock_keys = false;
              bluetooth = false;
              caffeine = false;
              dnd = false;
              keyboard_backlight = false;
              media = false;
              nightlight = false;
              power_profile = false;
              privacy = false;
              wifi = false;
            };
          };

          audio = {
            enable_overdrive = false;
            enable_volume_sounds = false;
          };

          shell.mpris.blacklist = [ ];

          brightness = {
            enable_ddcutil = false;
            minimum_brightness = 0.01;
          };

          theme = {
            mode = "dark";
            source = "builtin";
            builtin = "Catppuccin";
            sync_color_scheme = true;
            templates = {
              builtin_ids = [ ];
              enable_builtin_templates = false;
              enable_community_templates = false;
            };
          };

          nightlight = {
            enabled = false;
            force = false;
            temperature_night = 4000;
            temperature_day = 6500;
          };

          idle = {
            pre_action_fade_seconds = 5.0;
            behavior = {
              screen-off = {
                action = "screen_off";
                timeout = 300.0;
                enabled = true;
              };
              lock = {
                action = "lock";
                timeout = 600.0;
                enabled = true;
              };
              lock-and-suspend = {
                action = "lock_and_suspend";
                timeout = 900.0;
                enabled = true;
              };
            };
          };
        };
      };
    };
}
