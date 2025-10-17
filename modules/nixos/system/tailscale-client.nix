{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.system.tailscale-client;
in {
  options.system.tailscale-client = {enable = mkEnableOption "tailscale-client";};

  config = mkIf cfg.enable {
    sops.secrets.tailscale-auth-key = {};
    networking.firewall.trustedInterfaces = ["tailscale0"];

    services.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.tailscale-auth-key.path;
      openFirewall = true;
      useRoutingFeatures = "client";
      extraUpFlags = ["--accept-routes"];
    };
  };
}
