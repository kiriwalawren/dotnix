{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      # Set fish as default in bash
      programs.bash.interactiveShellInit = ''
        if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
        fi
      '';
      programs.fish.enable = true;
    };

  flake.modules.homeManager.base =
    { pkgs, ... }:
    let
      gitMainOrMaster = "git branch -l main master --format '%(refname:short)'";
    in
    {
      catppuccin.fish.enable = true;

      programs = {
        dircolors.enableFishIntegration = true;
        fzf.enableFishIntegration = true;
        kitty.shellIntegration.enableFishIntegration = true;
        git.enable = true; # required for hydro plugin

        fish = {
          enable = true;

          shellInit = ''
            set fish_greeting # Disable greeting
            set hydro_color_pwd $fish_color_cwd
            set hydro_color_git $fish_color_host
            set hydro_color_prompt $fish_color_host_remote
            fish_vi_key_bindings
          '';

          shellAliases = {
            # Basic
            dir = "dir --color=auto";
            egrep = "egrep --color=auto";
            fgrep = "fgrep --color=auto";
            grep = "grep --color=auto";
            la = "ls -lah --group-directories-first";
            ls = "ls -h --color=auto --group-directories-first";
            c = "wl-copy";
            p = "wl-paste";

            # Navigation
            eimer = "cd ~/gitrepos/eimer";
            dotnix = "cd ~/gitrepos/dotnix";
            nixflix = "cd ~/gitrepos/nixflix";
            secrets = "cd ~/gitrepos/secrets";

            # Nix
            ns = "NIXPKGS_ALLOW_UNFREE=1 nix-shell -p";
          };

          shellAbbrs = rec {
            # Git
            ga = "git add";
            gaa = "git add --all";
            gb = "git branch";
            gbd = "git branch -D";
            gbda = "git remote prune origin";
            gco = "git checkout";
            gcom = "git checkout $(${gitMainOrMaster})";
            gcoml = "${gcom} && ${ggl}";
            gcb = "git checkout -b";
            gcm = "git commit -m";
            gcma = "${gaa} && git commit -m";
            gcsmg = "git commit -m";
            "gcn!" = "git commit --verbose --amend --no-edit";
            "gcan!" = "git commit --verbose --amend --no-edit --all";
            gd = "git diff";
            gdca = "git diff --cached";
            gf = "git fetch";
            gp = "git push";
            ggp = "git push --set-upstream origin $(git branch --show-current)";
            ggf = "${ggp} -f";
            gl = "git pull";
            ggl = "git pull origin $(git branch --show-current)";
            gr = "git reset";
            "gr!" = "git reset --hard HEAD~";
            "gro!" = "git reset --hard origin/$(git branch --show-current)";
            grs = "git reset --soft HEAD~";
            "goops" = grs;
            grb = "git rebase";
            grbm = "git rebase $(${gitMainOrMaster})";
            gst = "git status";
            gsta = "git stash push";
            gstp = "git stash pop";
            gstc = "git stash clear";
            gm = "git merge";
            gmm = "git merge $(${gitMainOrMaster})";
            gmc = "git merge --continue";

            # Nix Helper
            nhb = "nh os boot";
            nhc = "nh clean all --keep 10 --keep-since 10d";
            nhcn = "${nhc} -n";
            nhr = "nh os switch";
            nhrc = "${nhr} && ${nhc}";
            nhrcn = "${nhrn} && ${nhcn}";
            nhrn = "${nhr} -n";
            nhs = "nh search";
            nht = "nh os test";

            # systemctl
            sc = "sudo systemctl";
            scu = "systemctl --user";
            sct = "${sc} status";
            scut = "${scu} status";
            scs = "${sc} show";
            scus = "${scu} show";
            "sc!" = "${sc} stop";
            "scu!" = "${scu} stop";
            scr = "${sc} restart";
            scur = "${scu} restart";
            scl = "${sc} list-units";
            scul = "${scu} list-units";
            jn = "journalctl -xeu";

            # Basic
            md = "mkdir -vp";
            rmf = "rm -rf";

            # Direnv
            da = "direnv allow";
            dd = "direnv disallow";
            duf = "echo 'use flake' > .envrc && direnv allow";
          };

          plugins = with pkgs; [
            {
              name = "hydro";
              inherit (fishPlugins.hydro) src;
            }
            {
              name = "autopair";
              inherit (fishPlugins.autopair) src;
            }
            {
              name = "fish-completion-sync";
              src = pkgs.fetchFromGitHub {
                owner = "pfgray";
                repo = "fish-completion-sync";
                rev = "ba70b6457228af520751eab48430b1b995e3e0e2";
                sha256 = "sha256-JdOLsZZ1VFRv7zA2i/QEZ1eovOym/Wccn0SJyhiP9hI=";
              };
            }
          ];
        };
      };
    };
}
