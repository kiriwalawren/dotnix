{
  config,
  lib,
  pkgs,
  ...
}: let
  arrCommon = import ./arr-common {inherit config lib pkgs;};
in
  arrCommon.mkArrModule {
    serviceName = "prowlarr";
    port = 9696;
    defaultBranch = "master";
    defaultApiVersion = "v1";
    usesDynamicUser = true;
  }
