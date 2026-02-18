{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.system.cachix-agent;
in
{
  options.system.cachix-agent = {
    enable = mkEnableOption "cachix-agent";
  };

  config = mkIf cfg.enable {
    sops.secrets.cachix-agent-token = { };

    services.cachix-agent = {
      enable = true;
      credentialsFile = config.sops.secrets.cachix-agent-token.path;
    };
  };
}
