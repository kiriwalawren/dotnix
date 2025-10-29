{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  inherit (config) server;
  cfg = config.server.postgres;
  stateDir = "${server.stateDir}/postgres";
in {
  options.server.postgres = {
    enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "Whether or not to enable postgresql.";
    };
  };

  config = mkIf (server.enable && cfg.enable) {
    # Register directories to be created
    server.dirRegistrations = [
      {
        dir = stateDir;
        owner = "postgres";
        group = "postgres";
        mode = "0700";
      }
    ];

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      dataDir = stateDir;
    };

    systemd.services.postgresql = {
      after = ["server-setup-dirs.service"];
      requires = ["server-setup-dirs.service"];
    };
  };
}
