{
  perSystem =
    { pkgs, ... }:
    {
      packages.noctalia-theme-hook = pkgs.writeShellApplication {
        name = "noctalia-theme-hook";

        runtimeInputs = with pkgs; [
          jq
          tmux
          fish
          gnused
          coreutils
        ];

        text = builtins.readFile ./_noctalia-theme-hook.sh;
      };
    };
}
