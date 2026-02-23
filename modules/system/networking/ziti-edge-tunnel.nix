{ inputs, ... }:
{
  flake.modules.nixos.ziti-edge-tunnel = {
    imports = [ inputs.ziti-edge-tunnel.nixosModules.default ];

    programs.ziti-edge-tunnel.enable = true;
  };
}
