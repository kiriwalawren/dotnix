{
  flake.modules.nixos.homelab =
    { config, pkgs, ... }:
    let
      inherit (config.services.ollama) port;
    in
    {
      services.ollama = {
        enable = true;
        package = pkgs.ollama-rocm; # MIT-licensed rocm build; `acceleration` option was removed from nixpkgs

        # Raw Ollama API has no auth. Only reachable through nginx below,
        # which is tailnet-only via the headscale extra_record.
        host = "127.0.0.1";
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

      services.nginx.virtualHosts."ai.${config.system.ddns.domain}" = {
        forceSSL = true;
        useACMEHost = config.system.ddns.domain;

        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          # Not recommendedProxySettings: when bound to loopback, Ollama's
          # allowedHostsMiddleware (server/routes.go) 403s any non-local Host.
          # Ollama FAQ's nginx example rewrites Host for the same reason.
          extraConfig = ''
            proxy_set_header Host localhost:${toString port};

            # stream tokens as they are generated instead of buffering
            proxy_buffering off;

            # loading a 19GB model can exceed nginx's 60s default before the first byte
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
          '';
        };
      };
    };
}
