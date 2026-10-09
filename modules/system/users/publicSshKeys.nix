{ lib, config, ... }:
let
  users = config.flake.users;
in
{
  flake = {
    users = {
      walawren.publicSshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ7Jim1eSW8QLx3IBg+ij2AT21XKBKJblndR6k4zk+iK";
      kiri.publicSshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDpdoTMvKosSsL4qw3F0HGNdgPAgkXIa2fMcDkrNzulM kiri@walawren.com";
    };
    publicSshKeys = lib.mapAttrsToList (_name: value: value.publicSshKey) users;

    modules.homeManager.base =
      { config, ... }:
      let
        user = config.home.username;
        inherit (config.home) email;
        key = users.${user}.publicSshKey;
      in
      {
        home = {
          file.".ssh/allowed_signers".text = ''
            ${email} ${key}
          '';
          file.".ssh/id_ed25519.pub".text = ''
            ${key}
          '';
        };
      };
  };
}
