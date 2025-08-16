{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.cli.fish;
  gitMainOrMaster = "git branch -l main master --format '%(refname:short)'";
in {
  meta.doc = lib.mdDoc ''
    Fish shell configuration with plugins and extensive command abbreviations.

    Provides a modern shell experience with:
    - [Fish shell](https://fishshell.com/) with vi key bindings
    - [Hydro](https://github.com/jorgebucaran/hydro) prompt theme
    - [Autopair](https://github.com/jorgebucaran/autopair.fish) for bracket completion
    - [Fish completion sync](https://github.com/pfgray/fish-completion-sync) for better completions
    - Comprehensive abbreviations for Git, Terraform, Pulumi, and Nix workflows
    - Integration with dircolors, fzf, and kitty
  '';

  options.cli.fish = {
    enable = mkEnableOption (lib.mdDoc "Fish shell with plugins and workflow abbreviations");
  };
  config = mkIf cfg.enable {
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
          ggp = "git push origin $(git branch --show-current)";
          ggf = "git push origin $(git branch --show-current) -f";
          gl = "git pull";
          ggl = "git pull origin $(git branch --show-current)";
          gr = "git reset";
          "gr!" = "git reset --hard HEAD~";
          "goops" = "git reset --hard HEAD~";
          "gro!" = "git reset --hard origin/$(git branch --show-current)";
          grs = "git reset --soft HEAD~";
          grb = "git rebase";
          grbm = "git rebase $(${gitMainOrMaster})";
          gst = "git status";
          gsta = "git stash push";
          gstp = "git stash pop";
          gstc = "git stash clear";
          gm = "git merge";
          gmm = "git merge $(${gitMainOrMaster})";
          gmc = "git merge --continue";

          # .NET
          db = "dotnet build";
          dr = "dotnet run";

          # Terraform
          tfa = "terraform apply";
          tfaa = "terraform apply -auto-approve";
          tfd = "terraform destroy";
          tfda = "terraform destroy -auto-approve";
          tfi = "terraform init";
          tfp = "terraform plan";
          tfr = "terraform refresh";
          tfs = "terraform show";
          tfsl = "terraform state list";
          tfsr = "terraform state remove";
          tft = "terraform taint";
          tfv = "terraform version";

          # OpenTofu
          otfa = "tofu apply";
          otfaa = "tofu apply -auto-approve";
          otfd = "tofu destroy";
          otfda = "tofu destroy -auto-approve";
          otfi = "tofu init";
          otfp = "tofu plan";
          otfr = "tofu refresh";
          otfs = "tofu show";
          otfsl = "tofu state list";
          otfsr = "tofu state remove";
          otft = "tofu taint";
          otfv = "tofu version";

          # Terragrunt
          tga = "terragrunt apply";
          tgaa = "terragrunt apply -auto-approve";
          tgd = "terragrunt destroy";
          tgda = "terragrunt destroy -auto-approve";
          tgi = "terragrunt init";
          tgp = "terragrunt plan";
          tgr = "terragrunt refresh";
          tgs = "terragrunt show";
          tgsl = "terragrunt state list";
          tgsr = "terragrunt state remove";
          tgt = "terragrunt taint";
          tgv = "terragrunt version";

          # Pulumi
          pl = "pulumi login";
          pu = "pulumi up";
          puy = "pulumi up -y";

          # Nix Helper
          nhr = "nh os switch";
          nhrn = "${nhr} -n";
          nhb = "nh os boot";
          nht = "nh os test";
          nhs = "nh search";
          nhc = "nh clean all --keep 10 --keep-since 10d";
          nhcn = "${nhc} -n";
          nhrc = "${nhr} && ${nhc}";
          nhrcn = "${nhrn} && ${nhcn}";

          # Basic
          ls = "ls -h --color=auto --group-directories-first";
          la = "ls -lah --group-directories-first";
          md = "mkdir -vp";
          dir = "dir --color=auto";
          grep = "grep --color=auto";
          fgrep = "fgrep --color=auto";
          egrep = "egrep --color=auto";
          loc = "scc --no-cocomo";
          rmf = "rm -rf";

          # Tmux
          tmk = "tmux kill-session";
          tmkk = "tmux kill-server";

          # Direnv
          duf = "echo 'use flake' >> .envrc && direnv allow";
          da = "direnv allow";
          dd = "direnv disallow";
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
