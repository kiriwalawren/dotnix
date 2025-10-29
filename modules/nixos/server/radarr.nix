{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) server;
  mediaDir = "${server.mediaDir}/movies";
in {
  imports = [(import ./arr-common/mkArrServiceModule.nix "radarr" {inherit config lib pkgs;})];

  config.server.radarr = {
    group = lib.mkDefault "media";
    mediaDirs = lib.mkDefault [
      {
        dir = mediaDir;
        owner = "root";
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
