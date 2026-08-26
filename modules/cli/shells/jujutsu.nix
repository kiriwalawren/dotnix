{ config, ... }:
let
  inherit (config.user) email;
  name = config.user.displayName;
in
{
  flake.modules.homeManager.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.jujutsu = {
        enable = true;

        settings = {
          user = {
            inherit name email;
          };

          signing = {
            behavior = "own";
            backend = "ssh";
            key = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
            backends.ssh.allowed-signers = "${config.home.homeDirectory}/.ssh/allowed_signers";
          };

          # Prevent pushing work in progress or anything explicitly labeled "private"
          git.private-commits = "description('wip:*') | description('private:*')";

          working-copy.eol-conversion = "input";

          snapshot.auto-update-stale = true;

          ui = lib.mkIf config.programs.diff-so-fancy.enable (
            let
              diffCmd = "${lib.getExe pkgs.diff-so-fancy}";
            in
            {
              default-command = "status";
              diff-formatter = ":git";
              diff-editor = ":builtin";
              pager = [
                "sh"
                "-c"
                "${diffCmd} | less -RFX"
              ];
            }
          );

          colors = {
            "diff added token" = {
              underline = false;
            };
            "diff removed token" = {
              underline = false;
            };
          };
        };
      };
    };
}
