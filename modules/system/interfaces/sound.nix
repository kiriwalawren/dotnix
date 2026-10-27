{ self, ... }: {
  flake.wrappers.niri =
    { lib, pkgs, ... }:
    let
      noctalia =
        cmd:
        [
          (lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia)
          "msg"
        ]
        ++ (lib.splitString " " cmd);
    in
    {
      settings = {
        binds = {
          "XF86AudioRaiseVolume".spawn = noctalia "volume-up";
          "XF86AudioLowerVolume".spawn = noctalia "volume-down";
          "XF86AudioMute".spawn = noctalia "volume-mute";
          "CTRL+Space".spawn = noctalia "mic-mute";
        };

        window-rules = [
          {
            matches = [ { app-id = "wiremix"; } ];
            open-floating = true;
            default-column-width.fixed = 750;
            default-window-height.fixed = 700;
            opacity = 1.0;
          }
        ];
      };
    };

  flake.modules.nixos.sound = { config, ... }: {
    users.users.${config.user.name}.extraGroups = [
      "audio"
      "sound"
    ];

    programs.noisetorch.enable = true; # Mic Noise Filter

    security.rtkit.enable = true;
    services = {
      pulseaudio.support32Bit = true;
      pipewire = {
        enable = true;

        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
      };
    };
  };

  flake.modules.homeManager.sound =
    { lib, pkgs, ... }:
    let
      pamixer = "${lib.getExe pkgs.pamixer}";

      unmutemic = pkgs.writeShellScriptBin "unmutemic" ''
        ${pamixer} --list-sources | tail -n +2 | awk '{print $1}' | while read -r source; do
          ${pamixer} -u --source "$source"
        done
      '';

      mutemic = pkgs.writeShellScriptBin "mutemic" ''
        ${pamixer} --list-sources | tail -n +2 | awk '{print $1}' | while read -r source; do
          ${pamixer} -m --source "$source"
        done
      '';

      togglemic = pkgs.writeShellScriptBin "togglemic" ''
        ${pamixer} --list-sources | tail -n +2 | awk '{print $1}' | while read -r source; do
          ${pamixer} -t --source "$source"
        done
      '';
    in
    {
      home.packages = [
        unmutemic
        mutemic
        togglemic
        pkgs.wiremix
      ];
    };
}
