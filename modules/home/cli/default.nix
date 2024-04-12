{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.modules.cli;
in {
  imports = [
    ./dircolors.nix
    ./direnv.nix
    ./git.nix
    ./nvim.nix
    ./tmux.nix
    ./zsh
  ];

  options.modules.cli = {enable = mkEnableOption "cli";};

  config = mkIf cfg.enable {
    modules.cli = {
      dircolors.enable = true;
      direnv.enable = true;
      git.enable = true;
      nvim.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };
  };
}
