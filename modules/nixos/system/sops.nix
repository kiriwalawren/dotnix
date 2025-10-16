{
  config,
  inputs,
  ...
}: let
  inherit (config.users.users.${config.user.name}) group;
  user = config.user.name;
in {
  imports = [inputs.sops-nix.nixosModules.sops];

  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;
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
      "passwords/${user}".neededForUsers = !config.wsl.enable;
      "${config.user.name}_ssh_key" = {
        inherit group;
        mode = "0440";
        neededForUsers = true;
        owner = user;
      };
    };
  };

  # This is needed because `sops.secrets.<secret>.owner`
  # and `sops.secrets.<secret>.group` does not work.
  system.activationScripts.fixSecretPermissions.text = ''
    chown ${user}:users /run/secrets-for-users/${user}_ssh_key
    chmod 0400 /run/secrets-for-users/${user}_ssh_key
  '';

  # Symlink SSH key to user's home directory for home-manager
  system.activationScripts.linkUserSshKey.text = ''
    mkdir -p /home/${user}/.ssh
    ln -sf /run/secrets-for-users/${user}_ssh_key /home/${user}/.ssh/${user}_ssh_key
    chown ${user}:users /home/${user}/.ssh
    chmod 0700 /home/${user}/.ssh
  '';
}
