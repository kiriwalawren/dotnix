{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) server;
  mediaDir = "${server.mediaDir}/music";
in {
  imports = [(import ./arr-common/mkArrServiceModule.nix "lidarr" {} {inherit config lib pkgs;})];

  config.server.lidarr = {
    group = lib.mkDefault "media";
    mediaDirs = lib.mkDefault [
      {
        dir = mediaDir;
        owner = "root";
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
