{
  flake.modules.nixos.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.system.dual-function-keys;

      keyMappingType = lib.types.submodule {
        options = {
          tap = lib.mkOption {
            type = lib.types.oneOf [
              lib.types.str
              (lib.types.listOf lib.types.str)
            ];
            description = "Key code(s) to send when key is tapped";
          };
          hold = lib.mkOption {
            type = lib.types.oneOf [
              lib.types.str
              (lib.types.listOf lib.types.str)
            ];
            description = "Key code(s) to send when key is held";
          };
          hold-start = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.oneOf [
                lib.types.str
                (lib.types.listOf lib.types.str)
              ]
            );
            default = null;
            description = "Optional key(s) to send when key is held immediately";
          };
        };
      };

      # Each key in cfg is the physical key being pressed (e.g. "KEY_CAPSLOCK")
      mappings = lib.mapAttrsToList (
        key: opts:
        {
          KEY = key;
          TAP = opts.tap;
          HOLD = opts.hold;
        }
        // lib.optionalAttrs (opts.hold-start != null) {
          HOLD_START = opts.hold-start;
        }
      ) cfg;

      input-keys = builtins.attrNames cfg;
      listen-key-string = lib.strings.concatStringsSep ", " input-keys;

      config-yaml = lib.generators.toYAML { } { MAPPINGS = mappings; };
      config-file = pkgs.writeText "dual-function-keys.yaml" config-yaml;
    in
    {
      options.system.dual-function-keys = lib.mkOption {
        type = lib.types.attrsOf keyMappingType;
        default = { };
        description = "Declarative dual-function key remapping using interception-tools";
      };

      config = {
        system.dual-function-keys = {
          "KEY_CAPSLOCK" = {
            tap = "KEY_ESC";
            hold = "KEY_LEFTCTRL";
          };
        };

        services.interception-tools = {
          enable = true;
          plugins = [ pkgs.interception-tools-plugins.dual-function-keys ];
          udevmonConfig = ''
            - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.dual-function-keys}/bin/dual-function-keys -c ${config-file} | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
              DEVICE:
                EVENTS:
                  EV_KEY: [${listen-key-string}]
          '';
        };
      };
    };
}
