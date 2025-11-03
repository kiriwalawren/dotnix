{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.cli.git;
in {
  options.cli.git = {enable = mkEnableOption "git";};

  config = mkIf cfg.enable {
    programs = {
      git = {
        enable = true;

        ignores = ["Session.vim" "secrets.sh" "secrets.tfvars" "local.tfvars" ".claude/"];

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

      diff-so-fancy = {
        enable = true;
        enableGitIntegration = true;
        pagerOpts = ["--tabs=4" "-RFX"];
      };

      gh = {
        enable = true;
        gitCredentialHelper.enable = false;

        settings = {
          git_protocol = "ssh";
        };
      };

      ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks."*" = {
          forwardAgent = false;
          addKeysToAgent = "no";
          compression = false;
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlMaster = "no";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "no";
        };
      };
    };
  };
}
