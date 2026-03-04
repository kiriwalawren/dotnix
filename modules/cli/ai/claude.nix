{
  nixpkgs.config.allowUnfreePackages = [ "claude-code" ];

  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.claude-code ];

      home.file.".claude/CLAUDE.md".text = ''
        Never make a suggestion without first researching it, explaining your
        reasoning in depth (not just "it is because of this", but "it is because
        of this because..."), and citing the exact source that gave you this
        impression. If you cannot find research to substantiate your suggestion,
        DO NOT suggest it.
      '';
    };
}
