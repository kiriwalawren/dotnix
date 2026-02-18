{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.cli.nixvim;
in
{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./core
    ./plugins
  ];

  options.cli.nixvim = {
    enable = mkEnableOption "nixvim";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.claude-code ];
    programs = {
      ripgrep.enable = true;

      fd = {
        enable = true;
        hidden = true;
        ignores = [
          ".git/"
          "node_modules/"
          "dist"
        ];
      };

      fzf = {
        enable = true;
        defaultCommand = "fd --type f --color=always";
        defaultOptions = [
          "-m"
          "--height 50%"
          "--border"
        ];
      };

      nixvim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
      };
    };
  };
}
