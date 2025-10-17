{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.system.ddns;
in {
  options.system.ddns = with lib.types; {
    enable = mkEnableOption "ddns";

    domains = lib.mkOption {
      default = [""];
      type = listOf str;
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.cloudflare-api-token = {};
    services.cloudflare-dyndns = {
      inherit (cfg) domains;

      enable = true;
      ipv4 = true;
      ipv6 = false;
      proxied = true;
      deleteMissing = true;
      apiTokenFile = config.sops.secrets.cloudflare-api-token.path;
    };
  };
}
