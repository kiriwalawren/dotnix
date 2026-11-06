{ lib, self, ... }:
let
  keyboard = import ./_keyboard.nix { inherit lib; };
  inherit (keyboard) port layers rows;

  keys = lib.flatten rows;

  defsrc = lib.concatMapStringsSep "\n" (row: "  " + lib.concatMapStringsSep " " (k: k.src) row) rows;

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
        # Needed so `fork` can see shift/meta, which are not in defsrc
        extraDefCfg = "process-unmapped-keys yes";
        config = ''
          (defsrc
            caps
          ${defsrc})

          ;; Caps Lock: tap for Escape, hold for Control.
          ;; Timings match the previous interception-tools dual-function-keys
          ;; defaults: 150ms double-tap (tap-repress) window, 200ms tap window.
          (defalias cesc (tap-hold-press 150 200 esc lctl))

          ;; Number row: a symbol by default, a digit with shift (shift is released for the digit)
          (deftemplate dvp (base shifted)
            (fork $base (unshift $shifted) (lsft rsft)))

          ${deflayers}
        '';
      };
    };
  };

  flake.wrappers.niri = { pkgs, ... }: {
    settings.binds."Mod+I".spawn = [
      (lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.cycle-layout)
    ];
  };
}
