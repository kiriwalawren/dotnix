{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem = {
    treefmt = {
      projectRootFile = "flake.nix";

      programs = {
        # Nix
        nixfmt.enable = true;
        deadnix.enable = true;
        statix.enable = true;

        # Markdown
        mdformat.enable = true;

        # YAML
        yamlfmt.enable = true;

        # Shell
        shfmt.enable = true;
        shellcheck.enable = true;
      };

      settings = {
        excludes = [
          ".envrc"
          ".prettierignore"
          "**/.keep"
          "**/*.pub"
        ];
        on-unmatched = "fatal";
        global.excludes = [
          "*.jpg"
          "*.jpeg"
          "*.webp"
          "*.png"
          "LICENSE"
        ];
      };
    };
  };

  flake.modules.nixvim.base = {
    autoCmd = [
      {
        desc = "Automatically trim all whitespace an save";
        event = [ "BufWritePre" ];
        pattern = [ "*" ];
        command = ":%s/\\s\\+$//e";
      }
    ];

    keymaps = [
      {
        mode = [ "v" ];
        key = "<leader>o";
        action = ":sort<cr>";
        options.desc = "Sort Selected";
      }
    ];

    plugins.conform-nvim = {
      enable = true;

      settings = {
        notify_on_error = false;

        format_on_save = {
          lsp_fallback = "fallback";
          timeout_ms = 5000;
        };
      };
    };
  };
}
