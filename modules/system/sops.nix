{ inputs, ... }:
{
  flake.modules.nixos.base =
    { config, ... }:
    let
      inherit (config.users.users.${config.user.name}) group;
    in
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops = {
        defaultSopsFile = "${inputs.secrets}/secrets.yaml";
        validateSopsFiles = false;

        age = {
          # automatcally import host SSH keys as age keys
          sshKeyPaths = [
            "/etc/ssh/ssh_host_ed25519_key"
          ];

          keyFile = "/var/lib/sops-nix/key.txt";

          # generate a new key if the key specified above does not exist
          generateKey = true;
        };

        # secrets will be output to /run/secrets
        # e.g. /run/secrets/<secret-name>
        # secrets required for user creation are handled in the ./user.nix file
        # because they will be output to /run/secrets-for-users and only when the user is assigned to a host
        secrets = {
          "passwords/${config.user.name}".neededForUsers = !config.wsl.enable;
          "${config.user.name}_ssh_key" = {
            inherit group;
            mode = "0440";
            neededForUsers = true;
            owner = config.user.name;
          };
        };
      };

      # This is needed because `sops.secrets.<secret>.owner`
      # and `sops.secrets.<secret>.group` does not work.
      system.activationScripts.fixSecretPermissions.text = ''
        chown ${config.user.name}:users /run/secrets-for-users/${config.user.name}_ssh_key
        chmod 0400 /run/secrets-for-users/${config.user.name}_ssh_key
      '';

      # Symlink SSH key to user's home directory for home-manager
      system.activationScripts.linkUserSshKey.text = ''
        mkdir -p /home/${config.user.name}/.ssh
        ln -sf /run/secrets-for-users/${config.user.name}_ssh_key /home/${config.user.name}/.ssh/${config.user.name}_ssh_key
        ln -sf /run/secrets-for-users/${config.user.name}_ssh_key /home/${config.user.name}/.ssh/id_ed25519
        chown ${config.user.name}:users /home/${config.user.name}/.ssh
        chmod 0700 /home/${config.user.name}/.ssh
      '';
    };

  flake.modules.homeManager.base =
    {
      config,
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
    };
}
