{
  flake.modules.nixvim.base = {
    plugins = {
      lsp.servers.nil_ls.enable = true;

      conform-nvim.settings.formatters_by_ft.nix = {
        __unkeyed-1 = "nixfmt";
        __unkeyed-2 = "alejandra";
        __unkeyed-3 = "nixpkgs-fmt";
        stop_after_first = true;
      };
    };
  };

  flake.modules.homeManager.base = {
    programs.git.ignores = [
      "result"
      "result/*"
    ];
  };
}
