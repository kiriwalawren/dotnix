{
  flake.modules.nixvim.base.plugins = {
    none-ls.enable = true;
    lsp = {
      enable = true;
      keymaps = {
        lspBuf = {
          "gd" = {
            action = "definition";
            desc = "Goto Definitions";
          };
          "gr" = {
            action = "rename";
            desc = "Rename text across file";
          };
          "gD" = {
            action = "references";
            desc = "Goto References";
          };
          "gt" = {
            action = "type_definition";
            desc = "Goto Type Definitions";
          };
          "gi" = {
            action = "implementation";
            desc = "Goto implementation";
          };
          "K" = "hover";
          "<leader>ca" = {
            action = "code_action";
            desc = "Code Actions";
          };
        };
        diagnostic = {
          "<leader>dd" = {
            action = "open_float";
            desc = "Open Diagnostic List";
          };
          "<leader>d[" = {
            action = "goto_next";
            desc = "Goto Next Issue";
          };
          "<leader>d]" = {
            action = "goto_prev";
            desc = "Goto Prev Issue";
          };
        };
      };
    };
  };
}
