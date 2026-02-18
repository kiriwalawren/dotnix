{ config, ... }:
{
  flake.modules.nixos.installer =
    { lib, ... }:
    {
      users.users = {
        root = {
          initialHashedPassword = lib.mkForce "$y$j9T$M93AAG05U9RRsjhXIamCL/$YT5Eu.P4ci1hx11vb0P/loGWp6Qpz7hcENtUAj2jryC";
          openssh.authorizedKeys.keys = config.flake.users.sshKeys;
        };
        nixos = {
          initialHashedPassword = lib.mkForce "$y$j9T$M93AAG05U9RRsjhXIamCL/$YT5Eu.P4ci1hx11vb0P/loGWp6Qpz7hcENtUAj2jryC";
          openssh.authorizedKeys.keys = config.flake.users.sshKeys;
        };
      };
    };
}
