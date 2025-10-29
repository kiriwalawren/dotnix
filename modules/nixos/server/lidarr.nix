{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) server;
  inherit (server) globals;
  mediaDir = "${server.mediaDir}/music";
  arrCommon = import ./arr-common {inherit config lib pkgs;};
in
  arrCommon.mkArrModule {
    serviceName = "lidarr";
    port = 8686;
    defaultBranch = "master";
    defaultApiVersion = "v1";
    mediaDirs = [
      {
        dir = mediaDir;
        owner = globals.libraryOwner.user;
      }
    ];
    rootFolders = [
      {
        path = mediaDir;
        defaultQualityProfileId = 2;
        defaultMetadataProfileId = 1;
        defaultMonitorOption = "all";
        defaultNewItemMonitorOption = "all";
        defaultTags = [];
        name = "default";
      }
    ];
  }
