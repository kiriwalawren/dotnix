{
  flake.modules.homeManager.base.programs = {
    ripgrep.enable = true;

    fd = {
      enable = true;
      hidden = true;
      ignores = [
        ".git/"
        "node_modules/"
        "dist"
      ];
    };

    fzf = {
      enable = true;
      defaultCommand = "fd --type f --color=always";
      defaultOptions = [
        "-m"
        "--height 50%"
        "--border"
      ];
    };
  };
}
