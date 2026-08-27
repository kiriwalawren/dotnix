{ config, ... }:
let
  inherit (config.user) email;
  name = config.user.displayName;
in
{
  flake.modules.homeManager.base =
    { config, ... }:
    {
      programs.git = {
        enable = true;
        signing.format = "openpgp";

        ignores = [
          "Session.vim"
          "secrets.sh"
          "secrets.tfvars"
          "local.tfvars"
          ".claude/"
          ".omc/"
        ];

        settings = {
          user = {
            inherit name email;
          };

          gpg = {
            format = "ssh";
            ssh.allowedSignersFile = "${config.home.homeDirectory}/.ssh/allowed_signers";
          };
          user.signingKey = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
          commit.gpgSign = true;

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
    };
}
