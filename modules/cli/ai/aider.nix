{
  # aider-chat depends on posthog, which nixpkgs marked broken (7d2d1cfd06) when
  # mcp was bumped to 2.x. mcp is only a posthog test input and only one test
  # fails against mcp 2. Remove this once NixOS/nixpkgs#578265 lands.
  nixpkgs.overlays = [
    (_: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (_: pyPrev: {
          posthog = pyPrev.posthog.overridePythonAttrs (old: {
            disabledTests = (old.disabledTests or [ ]) ++ [
              "test_prepare_tool_result_delivers_into_call_tool_result_models"
            ];
            meta = old.meta // {
              broken = false;
            };
          });
        })
      ];
    })
  ];

  flake.modules.homeManager.laptop = { osConfig, ... }: {
    programs.aider-chat = {
      enable = true; # home-manager module; pulls pkgs.aider-chat automatically
      settings.model = "ollama_chat/qwen3-coder:30b"; # note ollama_chat/ prefix, not ollama/
    };

    home.sessionVariables.OLLAMA_API_BASE = "https://ai.${osConfig.system.ddns.domain}";
  };
}
