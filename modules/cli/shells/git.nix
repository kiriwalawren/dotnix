{ config, ... }:
let
  user = config.user.name;
  inherit (config.user) email;
  key = config.flake.users.${user}.publicSshKey;
in
{
  flake.modules.homeManager.base =
    { config, ... }:
    {
      home = {
        file.".ssh/allowed_signers".text = ''
          ${email} ${key}
        '';
        file.".ssh/id_ed25519.pub".text = ''
          ${key}
        '';
      };

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
            name = "Kiri Carlson";
            inherit email;
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
