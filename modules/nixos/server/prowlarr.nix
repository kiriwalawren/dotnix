{
  config,
  lib,
  pkgs,
  ...
}: let
  arrCommon = import ./arr-common {inherit config lib pkgs;};
in {
  imports = [
    (arrCommon.mkArrServiceModule "prowlarr")
  ];

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
