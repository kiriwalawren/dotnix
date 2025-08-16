{
  config,
  hostConfig,
  lib,
  ...
}:
with lib; let
  cfg = config.cli.git;
in {
  meta.doc = lib.mdDoc ''
    Git configuration with GitHub CLI integration and SSH key management.

    Provides a complete Git development environment with:
    - [Git](https://git-scm.com/) version control
    - Enhanced diffs using [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy)
    - [GitHub CLI](https://cli.github.com/) with SSH protocol
    - Automatic SSH key linking from [SOPS](https://github.com/getsops/sops) secrets
    - Sensible gitignore defaults for common development files
  '';

  options.cli.git = {
    enable = mkEnableOption (lib.mdDoc "Git version control with GitHub CLI integration");
  };

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
      };
    };

    home.activation.linkUserSshKey = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p ~/.ssh
      chmod 700 ~/.ssh
      ln -sf /run/secrets-for-users/${config.home.username}_ssh_key ~/.ssh/id_ed25519
    '';
  };
}
