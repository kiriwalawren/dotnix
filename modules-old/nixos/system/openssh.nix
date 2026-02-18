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

    networking.firewall.allowedTCPPorts = [ 22 ];
  };
}
