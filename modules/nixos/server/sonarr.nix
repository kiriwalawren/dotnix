{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) server;
  tvDir = "${server.mediaDir}/tv";
  animeDir = "${server.mediaDir}/anime";
in {
  imports = [(import ./arr-common/mkArrServiceModule.nix "sonarr" {} {inherit config lib pkgs;})];

  config.server.sonarr = {
    group = lib.mkDefault "media";
    mediaDirs = lib.mkDefault [
      {
        dir = tvDir;
        owner = "root";
      }
      {
        dir = animeDir;
        owner = "root";
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
