{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.cli.dircolors;
in {
  meta.doc = lib.mdDoc ''
    Directory and file color configuration for terminal listings.

    Enables [dircolors](https://www.gnu.org/software/coreutils/manual/html_node/dircolors-invocation.html)
    to provide colored output for `ls` and other file listing commands, making it easier
    to distinguish between different file types and directories at a glance.
  '';

  options.cli.dircolors = {
    enable = mkEnableOption (lib.mdDoc "colored file listings with dircolors");
  };

  config = mkIf cfg.enable {
    programs.dircolors.enable = true;
  };
}
