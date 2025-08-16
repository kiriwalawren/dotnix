{
  config,
  inputs,
  lib,
  ...
}:
with lib; let
  cfg = config.cli.nixvim;
in {
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./core
    ./plugins
  ];

  meta.doc = lib.mdDoc ''
    Neovim configuration using Nixvim with comprehensive plugin setup.
    
    Provides [Neovim](https://neovim.io/) via [Nixvim](https://github.com/nix-community/nixvim) with:
    - Complete core configuration (autocmds, keymaps, options, theme)
    - LSP and completion plugins for development
    - Editor plugins for enhanced functionality
    - Treesitter for syntax highlighting and navigation
    - Supporting tools: ripgrep, fd, and fzf for file operations
    - Set as default editor with vi/vim aliases
  '';

  options.cli.nixvim = {
    enable = mkEnableOption (lib.mdDoc "Neovim with comprehensive plugin configuration");
  };

  config = mkIf cfg.enable {
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
        defaultOptions = ["-m" "--height 50%" "--border"];
      };

      nixvim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        nixpkgs.config.allowUnfree = true;
      };
    };
  };
}
