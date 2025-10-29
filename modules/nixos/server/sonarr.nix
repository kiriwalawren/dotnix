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
in {
  imports = [
    (arrCommon.mkArrServiceModule "sonarr")
  ];

  config.server.sonarr = {
    mediaDirs = lib.mkDefault [
      {
        dir = tvDir;
        owner = globals.libraryOwner.user;
      }
      {
        dir = animeDir;
        owner = globals.libraryOwner.user;
      }
    ];
    config = {
      apiVersion = lib.mkDefault "v3";
      hostConfig = {
        port = lib.mkDefault 8989;
        branch = lib.mkDefault "main";
      };
      rootFolders = lib.mkDefault [
        {path = tvDir;}
        {path = animeDir;}
      ];
    };
  };
}
