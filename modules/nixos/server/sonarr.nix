{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) server;
  inherit (server) globals;
  tvDir = "${server.mediaDir}/tv";
  animeDir = "${server.mediaDir}/anime";
  arrCommon = import ./arr-common {inherit config lib pkgs;};
in
  arrCommon.mkArrModule {
    serviceName = "sonarr";
    port = 8989;
    defaultBranch = "main";
    mediaDirs = [
      {
        dir = tvDir;
        owner = globals.libraryOwner.user;
      }
      {
        dir = animeDir;
        owner = globals.libraryOwner.user;
      }
    ];
    rootFolders = [
      {path = tvDir;}
      {path = animeDir;}
    ];
  }
