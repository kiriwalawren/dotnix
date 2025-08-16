{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.cli.btop;
in {
  meta.doc = lib.mdDoc ''
    System resource monitor with interactive process viewer.

    Provides [btop++](https://github.com/aristocratos/btop), a modern resource monitor
    that displays usage and stats for CPU, memory, disks, network, and processes.
    Features a clean terminal interface with mouse support and customizable themes.
  '';

  options.cli.btop = {
    enable = mkEnableOption (lib.mdDoc "btop++ resource monitor");
  };

  config = mkIf cfg.enable {
    catppuccin.btop.enable = true;
    programs.btop = {
      enable = true;
    };
  };
}
