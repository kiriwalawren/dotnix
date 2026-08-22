{ inputs, config, ... }:
let
  user = config.user.name;

in
{
  flake.modules.nixos.ziti-edge-tunnel =
    { config, lib, ... }:
    let
      isFramework13 = config.networking.hostName == "framework13";
    in
    {
      imports = [ inputs.ziti-edge-tunnel.nixosModules.default ];

      sops.secrets."ziti-identities-jwts/framework13/freewave-production" = lib.mkIf isFramework13 { };
      sops.secrets."ziti-identities-jwts/framework13/freewave-dev-staging" = lib.mkIf isFramework13 { };
      sops.secrets."ziti-identities-jwts/framework13/freewave-qt9" = lib.mkIf isFramework13 { };

      system.tailscale.enable = lib.mkForce false;

      services.ziti-edge-tunnel = {
        enable = true;
        extraUsers = [ user ];

        enrollment.identities = {
          kcarlson-personal-lt-framework13-production = lib.mkIf isFramework13 {
            jwtFile = config.sops.secrets."ziti-identities-jwts/framework13/freewave-production".path;
          };
          kcarlson-personal-lt-framework13-dev-staging = lib.mkIf isFramework13 {
            jwtFile = config.sops.secrets."ziti-identities-jwts/framework13/freewave-dev-staging".path;
          };
          kcarlson-personal-lt-framework13-qt9 = lib.mkIf isFramework13 {
            jwtFile = config.sops.secrets."ziti-identities-jwts/framework13/freewave-qt9".path;
          };
        };
      };
    };
}
