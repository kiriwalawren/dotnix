_: {
  projectRootFile = "flake.nix";

  settings.excludes = [ ".envrc" ];

  # Nix
  programs.nixfmt.enable = true;
  programs.deadnix.enable = true;
  programs.statix.enable = true;

  # Markdown
  programs.mdformat.enable = true;

  # YAML
  programs.yamlfmt.enable = true;

  # Shell
  programs.shfmt.enable = true;
  programs.shellcheck.enable = true;
}
