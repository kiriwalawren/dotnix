{
  flake.modules.homeManager.base.programs.git = {
    enable = true;

    ignores = [
      "Session.vim"
      "secrets.sh"
      "secrets.tfvars"
      "local.tfvars"
      ".claude/"
    ];

    settings = {
      user = {
        name = "Kiri Carlson";
        email = "kiri@walawren.com";
      };

      core = {
        autocrlf = "input";
      };

      init = {
        defaultBranch = "main";
      };

      pull = {
        rebase = false;
      };
    };
  };
}
