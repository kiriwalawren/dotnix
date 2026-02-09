{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.ui.sound;
in
{
  options.ui.sound = {
    enable = mkEnableOption "sound";
  };

  config = mkIf cfg.enable {
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
}
