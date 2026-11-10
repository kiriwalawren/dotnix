{
  nixpkgs.config.allowUnfreePackages = [ "claude-code" ];

  flake.modules.homeManager.base = { pkgs, ... }: {
    home.packages = [ pkgs.claude-code ];

    home.file.".claude/CLAUDE.md".text = ''
      Never make a suggestion without first researching it, explaining your
      reasoning in depth (not just "it is because of this", but "it is because
      of this because..."), and citing the exact source that gave you this
      impression. If you cannot find research to substantiate your suggestion,
      DO NOT suggest it.

      Always use `jq` when parsing JSON from the command line. Do not use python to parse JSON from the commanline.

      If you make a change that you suspect will fix and issue or bug, and it doesn't work, you need to
      revert that change before moving on to the next idea for a fix. In short, you should always be
      reverting thing that don't work the way you expected to avoid leaving dead code around.
    '';
  };
}
