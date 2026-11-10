{
  flake.modules.homeManager.base.programs.diff-so-fancy = {
    enable = true;
    enableGitIntegration = true;
    pagerOpts = [
      "--tabs=4"
      "-RFX"
    ];
  };
}
