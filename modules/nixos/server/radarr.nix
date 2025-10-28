{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) server;
  inherit (server) globals;
  mediaDir = "${server.mediaDir}/movies";
  arrCommon = import ./arr-common.nix {inherit config lib pkgs;};
in
  arrCommon.mkArrModule {
    serviceName = "radarr";
    port = 7878;
    defaultBranch = "master";
    mediaDirs = [
      {
        dir = mediaDir;
        owner = globals.libraryOwner.user;
      }
    ];
    defaultRootFolders = [
      {path = mediaDir;}
    ];
  }
