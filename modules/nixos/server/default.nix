{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.server;
in {
  imports = [
    ./nixflix
  ];

  options.server = {
    enable = mkEnableOption "media server configuration";
  };

  config = mkIf cfg.enable {
    server.nixflix.enable = true;
  };
}
