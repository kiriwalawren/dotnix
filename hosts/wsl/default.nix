{
  name = "wsl";
  modules = [
    ../../modules/nixos
    {
      system = {
        stateVersion = "23.11"; # Update when reinstalling
        docker.enable = true;
        tailscale.enable = true;
      };

      wsl.enable = true;
    }
  ];
}
