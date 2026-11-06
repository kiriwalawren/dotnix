{
  flake.modules.nixos.homelab =
    { config, pkgs, ... }:
    {
      services.ollama = {
        enable = true;
        package = pkgs.ollama-rocm; # MIT-licensed rocm build; `acceleration` option was removed from nixpkgs

        # Raw Ollama API has no auth - bind to the tailscale IP only,
        # same pattern adguardhome.nix uses for serverIP, not a public
        # nginx+ACME hostname like immich/vaultwarden/headscale get.
        host = config.tailscale.ips.homelab; # "100.64.0.6", modules/server/networking/headscale.nix
        port = 11434;

        # RX 6950 XT (gfx1030/RDNA2) is on Ollama's official GPU support
        # list and nixpkgs' default rocm gpuTargets already includes
        # gfx1030, so this likely isn't needed. If `journalctl -u ollama`
        # shows "no compatible amdgpu detected" after first deploy,
        # uncomment (spoofs the card as its own true ISA, low risk):
        # rocmOverrideGfx = "10.3.0";

        # Declarative pull on activation. qwen3-coder:30b is a 30B-A3B
        # MoE model (only ~3B active params/token), 19GB Q4_K_M - slightly
        # over the 16GB VRAM alone, but MoE makes partial GPU/CPU-RAM
        # layer splitting far less painful than for a dense model this
        # size, and homelab has 32GB system RAM as overflow. No smaller
        # official Qwen3-Coder tag exists.
        loadModels = [ "qwen3-coder:30b" ];
      };
    };
}
