{
  config,
  inputs,
  ...
}: {
  imports = [inputs.sops-nix.nixosModules.sops];

  sops = {
    defaultSopsFile = ../../../secrets.yaml;
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
      "private_keys/${config.user.name}" = {
        path = "/home/${config.user.name}/.ssh/${config.user.name}_ssh_key";
        neededForUsers = true;
      };
    };
  };
}
