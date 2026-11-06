{ lib, self, ... }:
let
  keyboard = import ./_keyboard.nix { inherit lib; };
  inherit (keyboard)
    port
    layers
    rows
    holdLayers
    extraKeys
    modLayers
    ;

  keys = lib.flatten rows;

  # Left-hand keys per row (the rest are right), for `defhands`
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

  extraMappings = lib.concatMapStringsSep "\n" (k: "  ${k.src} ${k.action}") extraKeys;

  # Base layer bodies (all also get Caps Lock and space)
  layerBodies = {
    dvorak = dvorakMappings;
    # Only keys with a `qwertyHold`
    qwerty = lib.concatMapStringsSep "\n" (k: "  ${k.src} ${k.qwertyAction}") (
      lib.filter (k: k ? qwertyAction) keys
    );
  };

  # In `layers` order; kanata starts in the first
  deflayers = lib.concatMapStringsSep "\n\n" (name: ''
    (deflayermap (${name})
      caps @cesc
    ${extraMappings}
    ${layerBodies.${name}})'') layers;

  # `cycle-layout` virtual key cases: switch to the next layout and announce it
  pushPrefix = "layout:";
  cycleCases = lib.concatStringsSep "\n" (
    lib.imap0 (
      i: layer:
      let
        next = lib.elemAt layers (lib.mod (i + 1) (lib.length layers));
      in
      "    ((base-layer ${layer})) (multi (layer-switch ${next}) (push-msg \"${pushPrefix}${next}\")) break"
    ) layers
  );

  # Empty layers held with hyper/meh, so the overlay sees the chord
  defmodlayers = lib.concatMapStringsSep "\n" (name: "(deflayermap (${name}))") (
    lib.attrNames modLayers
  );

  # After the base layers so kanata still starts in dvorak; unmapped keys fall through
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
        pkgs.util-linux # flock
      ];
      text = ''
        exec 3<>/dev/tcp/127.0.0.1/${toString port}

        # kanata picks the next layout (works while Hyper is held) and announces it via push-msg
        jq -cn '{ActOnFakeKey: {name: "cycle-layout", action: "Tap"}}' >&3

        next=""
        while ((SECONDS < 2)); do
          IFS= read -r -t "$((2 - SECONDS))" line <&3 || break
          err=$(jq -r '.Error.msg // empty' <<<"$line")
          if [[ -n "$err" ]]; then
            echo "kanata: $err" >&2
            exit 1
          fi
          # kanata 1.12 wraps push-msg strings in a list
          msg=$(jq -r '.MessagePush.message // empty | if type == "array" then .[0] else . end | strings' <<<"$line")
          if [[ "$msg" == ${pushPrefix}* ]]; then
            next="''${msg#${pushPrefix}}"
            break
          fi
        done
        exec 3>&-

        if [[ -z "$next" ]]; then
          echo "No reply from kanata" >&2
          exit 1
        fi

        echo "Keyboard layout: $next"
        # Only notify in a graphical session
        if [[ -n "''${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
          # Replace the previous notification so only the latest shows; flock avoids races
          id_file="''${XDG_RUNTIME_DIR:-/tmp}/cycle-layout.notification-id"
          exec 4>"$id_file.lock"
          flock 4
          replace=()
          if [[ -r "$id_file" ]] && [[ "$(<"$id_file")" =~ ^[0-9]+$ ]]; then
            replace=(--replace-id="$(<"$id_file")")
          fi
          if id=$(notify-send --app-name=kanata --print-id "''${replace[@]}" "Keyboard layout" "$next"); then
            printf '%s\n' "$id" >"$id_file"
          fi
        fi
      '';
    };
  };

  flake.modules.nixos.base = { pkgs, ... }: {
    environment.systemPackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.cycle-layout ];

    # The nixpkgs unit doesn't restart kanata after a crash
    systemd.services.kanata-main.serviceConfig.Restart = "on-failure";

    services.kanata = {
      enable = true;
      keyboards.main = {
        inherit port;
        # Let tap-hold decisions see keys outside defsrc (shift, enter, ...)
        extraDefCfg = "process-unmapped-keys yes";
        config = ''
          (defsrc
            caps
          ${defsrc})

          ;; Caps Lock: tap Esc, hold Ctrl (timings from the old dual-function-keys)
          (defalias cesc (tap-hold-press 150 200 esc lctl))

          ;; Modifier chords; each also holds a same-named empty layer for the overlay
          (defvar
            meh (multi lalt lsft lctl (layer-while-held meh))
            hyper (multi lalt lsft lctl lmet (layer-while-held hyper)))

          ;; Cycles the base layout (ignores held layers); tapped over TCP by `cycle-layout`
          (defvirtualkeys
            cycle-layout (switch
          ${cycleCases}))

          ;; Physical hands, for tap-hold-opposite-hand
          (defhands
            (left ${handKeys "left"})
            (right ${handKeys "right"}))

          ${deflayers}

          ${defholdlayers}

          ${defmodlayers}
        '';
      };
    };
  };

  flake.wrappers.niri = { pkgs, ... }: {
    # Keypad `.` from the numpad layer is Delete without Num Lock (no Num Lock key here)
    settings.input.keyboard.numlock = _: { };

    settings.binds."Mod+Ctrl+Alt+Shift+I" =
      import ../../../gui/desktop/niri/_bind.nix "Cycle keyboard layout"
        { spawn = [ (lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.cycle-layout) ]; };
  };
}
