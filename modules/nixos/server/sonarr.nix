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
  arrCommon = import ./arr-common.nix {inherit lib pkgs;};
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
    defaultRootFolders = [
      {path = tvDir;}
      {path = animeDir;}
    ];
  } {
    inherit config lib pkgs;
  }
