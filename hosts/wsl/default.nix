{
  name = "wsl";
  modules = [
    ../../modules/nixos
    {
      user.name = "kiri";
      system = {
        stateVersion = "23.11"; # Update when reinstalling
        docker.enable = true;
        tailscale.enable = true;
      };

      wsl.enable = true;
    }
  ];
}
