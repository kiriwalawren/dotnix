{ inputs, config, ... }:
let
  user = config.user.name;
in
{
  flake.modules.nixos.ziti-edge-tunnel =
    { config, lib, ... }:
    {
      imports = [ inputs.ziti-edge-tunnel.nixosModules.default ];

      sops.secrets."ziti-identities-jwts/framework13/freewave-dev-staging" = lib.mkIf (
        config.networking.hostName == "framework13"
      ) { };

      system.tailscale.enable = lib.mkForce false;

      services.ziti-edge-tunnel = {
        enable = true;
        extraUsers = [ user ];

        enrollment.identities = {
          kcarlson-personal-lt-framework13-dev-staging =
            lib.mkIf (config.networking.hostName == "framework13")
              {
                jwtFile = config.sops.secrets."ziti-identities-jwts/framework13/freewave-dev-staging".path;
              };
        };
      };
    };
}
