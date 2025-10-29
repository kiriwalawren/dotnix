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
in {
  imports = [
    (arrCommon.mkArrServiceModule "lidarr")
  ];

  config.server.lidarr = {
    mediaDirs = lib.mkDefault [
      {
        dir = mediaDir;
        owner = globals.libraryOwner.user;
      }
    ];
    config = {
      apiVersion = lib.mkDefault "v1";
      hostConfig = {
        port = lib.mkDefault 8686;
        branch = lib.mkDefault "master";
      };
      rootFolders = lib.mkDefault [
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
    };
  };
}
