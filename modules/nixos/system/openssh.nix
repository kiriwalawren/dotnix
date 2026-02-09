{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.system.openssh;
in
{
  options.system.openssh = {
    enable = mkEnableOption "openssh";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        StreamLocalBindUnlink = "yes";
        PermitRootLogin = "no"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
        GatewayPorts = "clientspecified";
      };

      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };

    services.fail2ban = {
      enable = true;
      ignoreIP = [
        # Whitelist some subnets
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "8.8.8.8" # whitelist a specific IP
        "nixos.wiki" # resolve the IP via DNS
      ];
    };

    networking.firewall.allowedTCPPorts = [ 22 ];
  };
}
