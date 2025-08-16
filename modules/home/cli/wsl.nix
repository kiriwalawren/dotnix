{
  hostConfig,
  lib,
  pkgs,
  ...
}:
with lib; {
  meta.doc = lib.mdDoc ''
    WSL-specific configuration for Windows Subsystem for Linux environments.

    Provides integration tools including:
    - [WSL utilities](https://github.com/wslutilities/wslu) for system integration
    - [wsl-open](https://github.com/4U6U57/wsl-open) for opening files with Windows applications
    - Custom xdg-open wrapper for seamless file handling
    - Browser integration with Windows host
  '';
  config = mkIf hostConfig.wsl.enable {
    home = {
      packages = with pkgs; [
        wslu
        wsl-open
        (pkgs.writeShellScriptBin "xdg-open" "exec -a $0 ${wsl-open}/bin/wsl-open $@")
      ];

      sessionVariables = {
        BROWSER = "wsl-open";
      };
    };
  };
}
