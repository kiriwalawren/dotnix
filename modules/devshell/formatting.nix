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
        yamlfmt = {
          enable = true;
          settings.formatter.retain_line_breaks_single = true;
        };

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
}
