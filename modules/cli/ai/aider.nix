{
  flake.modules.homeManager.laptop =
    { osConfig, ... }:
    {
      programs.aider-chat = {
        enable = true; # home-manager module; pulls pkgs.aider-chat automatically
        settings.model = "ollama_chat/qwen3-coder:30b"; # note ollama_chat/ prefix, not ollama/
      };

      home.sessionVariables.OLLAMA_API_BASE = "http://${osConfig.tailscale.ips.homelab}:11434";
    };
}
