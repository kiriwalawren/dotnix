{
  config,
  lib,
  pkgs,
  ...
}: {
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
