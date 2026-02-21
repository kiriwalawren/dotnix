{
  flake.modules.nixvim.base = {
    plugins = {
      lsp.servers.nil_ls.enable = true;

      conform-nvim.settings.formatters_by_ft.nix = {
        __unkeyed-1 = "alejandra";
        __unkeyed-2 = "nixpkgs-fmt";
        __unkeyed-3 = "nixfmt";
        stop_after_first = true;
      };
    };
  };

  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.nixfmt ];
      programs.git.ignores = [
        "result"
        "result/*"
      ];
    };
}
