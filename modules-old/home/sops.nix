{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    defaultSopsFile = "${inputs.secrets}/secrets.yaml";
    validateSopsFiles = false;

    age = {
      # automatcally import host SSH keys as age keys
      sshKeyPaths = [ "/home/${config.home.username}/.ssh/${config.home.username}_ssh_key" ];

      keyFile = "/home/${config.home.username}/.config/sops/age/keys.txt";

      # generate a new key if the key specified above does not exist
      generateKey = true;
    };
  };

  # I need this because `sops.age.generateKey` is not working
  home.activation.ensureAgeKeyDir = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    mkdir -p ~/.config/sops/age
    chmod 700 ~/.config/sops
    chmod 700 ~/.config/sops/age
    ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i ~/.ssh/${config.home.username}_ssh_key > ~/.config/sops/age/keys.txt
  '';
}
