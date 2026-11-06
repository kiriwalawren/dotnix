{ lib, self, ... }:
let
  keyboard = import ./_keyboard.nix { inherit lib; };
  inherit (keyboard)
    port
    layers
    rows
    holdLayers
    extraKeys
    ;

  keys = lib.flatten rows ++ extraKeys;

  # Which hand types each physical key, for `tap-hold-opposite-hand`.
  # The first N keys of each row (number row: grv..5) are the left hand.
  leftCounts = [
    6
    5
    5
    5
  ];
  hands = lib.zipListsWith (n: row: {
    left = lib.take n row;
    right = lib.drop n row;
  }) leftCounts rows;
  handKeys = side: lib.concatMapStringsSep " " (k: k.src) (lib.concatMap (r: r.${side}) hands);

  defsrc = lib.concatMapStringsSep "\n" (row: "  " + lib.concatMapStringsSep " " (k: k.src) row) (
    rows ++ [ extraKeys ]
  );

  dvorakMappings = lib.concatMapStringsSep "\n" (k: "  ${k.src} ${k.action}") (
    lib.filter (k: k.action != null) keys
  );

  # Layer bodies; every layer also gets the Caps Lock tap-hold
  layerBodies = {
    dvorak = dvorakMappings;
    qwerty = "";
  };

  # Layers are emitted in `layers` order: kanata starts in the first one
  deflayers = lib.concatMapStringsSep "\n\n" (name: ''
    (deflayermap (${name})
      caps @cesc
    ${layerBodies.${name}})'') layers;

  # Held layers come after the base layers so kanata still starts in the first
  # base layer. Unmapped keys are transparent (fall through to the base layer).
  defholdlayers = lib.concatStringsSep "\n\n" (
    lib.mapAttrsToList (name: mappings: ''
      (deflayermap (${name})
      ${
        lib.concatStringsSep "\n" (lib.mapAttrsToList (src: s: "  ${src} ${s.action}") mappings)
      })'') holdLayers
  );
in
{
  perSystem = { pkgs, ... }: {
    packages.cycle-layout = pkgs.writeShellApplication {
      name = "cycle-layout";
      runtimeInputs = [
        pkgs.jq
        pkgs.libnotify
      ];
      text = ''
        layers=(${lib.escapeShellArgs layers})

        exec 3<>/dev/tcp/127.0.0.1/${toString port}
        printf '%s\n' '{"RequestCurrentLayerName":{}}' >&3

        current=""
        while IFS= read -r -t 2 line <&3; do
          current=$(jq -r '.CurrentLayerName.name // empty' <<<"$line")
          [[ -n "$current" ]] && break
        done

        next="''${layers[0]}"
        for i in "''${!layers[@]}"; do
          if [[ "''${layers[$i]}" == "$current" ]]; then
            next="''${layers[$(((i + 1) % ''${#layers[@]}))]}"
            break
          fi
        done

        jq -cn --arg new "$next" '{ChangeLayer: {new: $new}}' >&3
        exec 3>&-

        echo "Keyboard layout: $next"
        # Only notify when there is a graphical session (no-op on headless systems)
        if [[ -n "''${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
          notify-send --app-name=kanata "Keyboard layout" "$next" || true
        fi
      '';
    };
  };

  flake.modules.nixos.base = { pkgs, ... }: {
    environment.systemPackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.cycle-layout ];

    services.kanata = {
      enable = true;
      keyboards.main = {
        inherit port;
        # Keys outside defsrc (shift, enter, ...) are otherwise invisible to
        # tap-hold decisions (config.adoc, process-unmapped-keys)
        extraDefCfg = "process-unmapped-keys yes";
        config = ''
          (defsrc
            caps
          ${defsrc})

          ;; Caps Lock: tap for Escape, hold for Control.
          ;; Timings match the previous interception-tools dual-function-keys
          ;; defaults: 150ms double-tap (tap-repress) window, 200ms tap window.
          (defalias cesc (tap-hold-press 150 200 esc lctl))

          ;; Modifier combos held by the dvorak tap-hold keys
          (defvar
            meh (multi lalt lsft lctl)
            hyper (multi lalt lsft lctl lmet))

          ;; Physical hands, used by tap-hold-opposite-hand (the hold keys)
          (defhands
            (left ${handKeys "left"})
            (right ${handKeys "right"}))

          ${deflayers}

          ${defholdlayers}
        '';
      };
    };
  };

  flake.wrappers.niri = { pkgs, ... }: {
    # The numpad layer sends keypad keys; with Num Lock off xkb maps keypad `.`
    # to KP_Delete. The Framework keyboard has no Num Lock key or keypad overlay.
    settings.input.keyboard.numlock = _: { };

    settings.binds."Mod+I".spawn = [
      (lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.cycle-layout)
    ];
  };
}
