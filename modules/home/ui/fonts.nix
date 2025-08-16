{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ui.fonts;
in {
  meta.doc = lib.mdDoc ''
    Font configuration for development and UI applications.

    Installs [Nerd Fonts](https://www.nerdfonts.com/) variants including:
    - [FiraMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/FiraMono) for terminal and code editing
    - [DroidSansMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/DroidSansMono) for alternative monospace needs

    Enables [fontconfig](https://www.freedesktop.org/wiki/Software/fontconfig/) for proper font discovery and rendering.
  '';

  options.ui.fonts = {
    enable = mkEnableOption (lib.mdDoc "development fonts with Nerd Font variants");
  };

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = true;

    home.packages = [
      pkgs.nerd-fonts.fira-mono
      pkgs.nerd-fonts.droid-sans-mono
    ];
  };
}
