{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.modules.cli.wsl;
in {
  options.modules.cli.wsl = {enable = mkEnableOption "wsl";};

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      wslu
      wsl-open
      (pkgs.writeShellScriptBin "xdg-open" "exec -a $0 ${wsl-open}/bin/wsl-open $@")
    ];

    home.sessionVariables = {
      BROWSER = "wsl-open";
    };
  };
}
