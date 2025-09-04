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
        diff-so-fancy = {
          enable = true;
          pagerOpts = ["--tabs=4" "-RFX"];
        };

        userName = "Kiri Carlson";
        userEmail = "kiri@walawren.com";

        ignores = ["Session.vim" "secrets.sh" "secrets.tfvars" "local.tfvars" ".claude/"];

        extraConfig = {
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

    home.activation.linkUserSshKey = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p ~/.ssh
      chmod 700 ~/.ssh
      ln -sf /run/secrets-for-users/${config.home.username}_ssh_key ~/.ssh/id_ed25519
    '';
  };
}
