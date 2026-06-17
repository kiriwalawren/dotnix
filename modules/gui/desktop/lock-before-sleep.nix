{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      systemd.user.services.lock-before-sleep = {
        Unit = {
          Description = "Lock screen before system sleep";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          Restart = "always";
          ExecStart = pkgs.writeShellScript "lock-before-sleep" ''
            ${pkgs.dbus}/bin/dbus-monitor --system \
              "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" |
            while read -r line; do
              if echo "$line" | grep -q "true"; then
                if command -v hyprlock > /dev/null 2>&1; then
                  hyprlock
                elif command -v noctalia-shell > /dev/null 2>&1; then
                  noctalia-shell ipc call lockScreen lock
                else
                  ${pkgs.systemd}/bin/loginctl lock-session
                fi
              fi
            done
          '';
        };
      };
    };
}
