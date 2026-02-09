{
  config,
  hostConfig,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.cli;
in
{
  imports = [
    ./btop.nix
    ./dircolors.nix
    ./direnv.nix
    ./fish.nix
    ./git.nix
    ./nixvim
    ./restish.nix
    ./tmux.nix
    ./wsl.nix
  ];

  options.cli = {
    enable = mkEnableOption "cli";
  };

  config = mkIf (cfg.enable || hostConfig.wsl.enable) {
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
      restish.enable = true;
      tmux.enable = true;
    };
  };
}
