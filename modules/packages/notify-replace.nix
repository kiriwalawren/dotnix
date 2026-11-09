{
  perSystem = { pkgs, ... }: {
    # `notify-replace <key> <notify-send args...>`: sends a notification that replaces the previous
    # one sent with the same key, so repeated presses don't stack notifications
    packages.notify-replace = pkgs.writeShellApplication {
      name = "notify-replace";
      runtimeInputs = [
        pkgs.libnotify
        pkgs.util-linux # flock
      ];
      text = ''
        if (($# < 2)); then
          echo "Usage: notify-replace <key> <notify-send args...>" >&2
          exit 1
        fi
        key=$1
        shift

        # Only notify in a graphical session
        [[ -n "''${DBUS_SESSION_BUS_ADDRESS:-}" ]] || exit 0

        # flock avoids races between rapid calls with the same key
        id_file="''${XDG_RUNTIME_DIR:-/tmp}/$key.notification-id"
        exec 4>"$id_file.lock"
        flock 4
        replace=()
        if [[ -r "$id_file" ]] && [[ "$(<"$id_file")" =~ ^[0-9]+$ ]]; then
          replace=(--replace-id="$(<"$id_file")")
        fi
        if id=$(notify-send --print-id "''${replace[@]}" "$@"); then
          printf '%s\n' "$id" >"$id_file"
        fi
      '';
    };
  };
}
