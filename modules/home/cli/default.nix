{
  config,
  hostConfig,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.cli;
in {
  imports = [
    ./btop.nix
    ./dircolors.nix
    ./direnv.nix
    ./fish.nix
    ./git.nix
    ./nixvim
    ./tmux.nix
    ./wsl.nix
  ];

  meta.doc = lib.mdDoc ''
    CLI module that enables all command-line development tools by default.

    When enabled, automatically enables: btop, dircolors, direnv, fish, git, nixvim, and tmux.
    Also includes scc (source code counter) and wl-clipboard packages.

    Note: This module is automatically enabled when `hostConfig.wsl.enable` is true.
  '';

  options.cli = {
    enable = mkEnableOption (lib.mdDoc "all CLI development tools");
  };

  config = mkIf (cfg.enable
    || hostConfig.wsl.enable) {
    home.packages = [
      pkgs.scc
      pkgs.wl-clipboard
    ];

    cli = {
      btop.enable = true;
      dircolors.enable = true;
      direnv.enable = true;
      fish.enable = true;
      git.enable = true;
      nixvim.enable = true;
      tmux.enable = true;
    };
  };
}
