{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.server;
in
{
  imports = [
    ./adguardhome.nix
    ./nixflix
  ];

  options.server = {
    enable = mkEnableOption "media server configuration";
  };

  config = mkIf cfg.enable {
    server.nixflix.enable = true;
    server.adguardhome.enable = true;
  };
}
