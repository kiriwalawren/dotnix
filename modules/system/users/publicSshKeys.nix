{ lib, ... }:
{
  flake = rec {
    users = {
      walawren.publicSshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ7Jim1eSW8QLx3IBg+ij2AT21XKBKJblndR6k4zk+iK";
      kiri.publicSshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDpdoTMvKosSsL4qw3F0HGNdgPAgkXIa2fMcDkrNzulM kiri@walawren.com";
    };
    publicSshKeys = lib.mapAttrsToList (_name: value: value.publicSshKey) users;
  };
}
