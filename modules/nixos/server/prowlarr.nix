{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [(import ./arr-common/mkArrServiceModule.nix "prowlarr" {inherit config lib pkgs;})];

  config.server.prowlarr = {
    usesDynamicUser = true;
    config = {
      apiVersion = lib.mkDefault "v1";
      hostConfig = {
        port = lib.mkDefault 9696;
        branch = lib.mkDefault "master";
      };
    };
  };
}
