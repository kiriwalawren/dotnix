{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption mkIf types;
  inherit (lib.generators) toYAML;
  inherit (lib.strings) concatStringsSep;

  cfg = config.system.dual-function-keys;

  keyMappingType = types.submodule {
    options = {
      tap = mkOption {
        type = types.oneOf [
          types.str
          (types.listOf types.str)
        ];
        description = "Key code(s) to send when key is tapped";
      };
      hold = mkOption {
        type = types.oneOf [
          types.str
          (types.listOf types.str)
        ];
        description = "Key code(s) to send when key is held";
      };
      hold-start = mkOption {
        type = types.nullOr (
          types.oneOf [
            types.str
            (types.listOf types.str)
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
  listen-key-string = concatStringsSep ", " input-keys;

  config-yaml = toYAML { } { MAPPINGS = mappings; };
  config-file = pkgs.writeText "dual-function-keys.yaml" config-yaml;
in
{
  options.system.dual-function-keys = mkOption {
    type = types.attrsOf keyMappingType;
    default = { };
    description = "Declarative dual-function key remapping using interception-tools";
  };

  config = mkIf (cfg != { }) {
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
}
