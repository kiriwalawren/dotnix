{
  config,
  lib,
  pkgs,
  ...
}: let
  prettierd_with_fallback = {
    __unkeyed-1 = "prettierd";
    __unkeyed-2 = "prettier";
    stop_after_first = true;
  };
in {
  meta.doc = lib.mdDoc ''
    Automatic code formatting for multiple languages using conform.nvim.

    Provides format-on-save functionality for:
    - JavaScript/TypeScript with prettierd/prettier
    - Nix with alejandra or nixpkgs-fmt
    - Elixir with mix format
    - Go with gofmt
    - Shell scripts with shfmt
    - C# with csharpier
    - CSS, HTML, and Markdown with prettier

    Features automatic formatting on save with LSP fallback, configurable timeout,
    and smart formatter selection with fallback options for reliable formatting.

    Links: [conform.nvim](https://github.com/stevearc/conform.nvim)
  '';

  config.home.packages = lib.mkIf config.programs.nixvim.enable (with pkgs; [shfmt prettierd]);

  config.programs.nixvim.plugins.conform-nvim = {
    enable = true;

    settings = {
      notify_on_error = false;

      formatters = {
        shfmt = {
          prepend_args = ["-i" "2" "-ci"];
        };
      };

      formatters_by_ft = {
        cs = ["csharpier"];
        css = prettierd_with_fallback;
        elixir = ["mix"];
        html = prettierd_with_fallback;
        javascript = prettierd_with_fallback;
        javascriptreact = prettierd_with_fallback;
        markdown = prettierd_with_fallback;
        nix = {
          __unkeyed-1 = "alejandra";
          __unkeyed-2 = "nixpkgs-fmt";
          stop_after_first = true;
        };
        typescript = prettierd_with_fallback;
        typescriptreact = prettierd_with_fallback;
        go = ["gofmt"];
        sh = ["shfmt"];
      };

      format_on_save = {
        lsp_fallback = "fallback";
        timeout_ms = 5000;
      };
    };
  };
}
