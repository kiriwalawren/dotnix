{
  flake.modules.homeManager.gui = { pkgs, ... }: {
    home.packages = [ pkgs.bitwarden-desktop ];
  };
}
