{
  config,
  lib,
  pkgs,
  ...
}: {
  meta.doc = lib.mdDoc ''
    Integration for Claude Code, Anthropic's CLI tool for AI-assisted development.

    Provides quick access to Claude Code within Neovim:
    - Floating terminal integration with toggleterm
    - Keybinding shortcuts for instant access (leader+cf)
    - Terminal mode navigation for seamless workflow
    - AI-powered code assistance and generation

    Enables developers to access Claude's capabilities directly from their editor
    for code review, generation, and problem-solving without leaving Neovim.

    Links: [Claude Code](https://claude.ai/code)
  '';

  config.home.packages = lib.mkIf config.programs.nixvim.enable [pkgs.claude-code];

  config.programs.nixvim = {
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>cf";
        action = "<cmd>4TermExec cmd=\"claude\" direction=float<cr>";
        options.desc = "Toggle Claude Code";
      }
      {
        mode = ["t"];
        key = "<leader>cf";
        action = "<cmd>4ToggleTerm direction=float<cr>claude";
        options.desc = "Toggle Claude Code";
      }
    ];
  };
}
