{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) server;
  inherit (server) globals;
  mediaDir = "${server.mediaDir}/movies";
  arrCommon = import ./arr-common {inherit config lib pkgs;};
in {
  imports = [
    (arrCommon.mkArrServiceModule "radarr")
  ];

  config.server.radarr = {
    mediaDirs = lib.mkDefault [
      {
        dir = mediaDir;
        owner = globals.libraryOwner.user;
      }
    ];
    config = {
      apiVersion = lib.mkDefault "v3";
      hostConfig = {
        port = lib.mkDefault 7878;
        branch = lib.mkDefault "master";
      };
      rootFolders = lib.mkDefault [
        {path = mediaDir;}
      ];
    };
  };
}
