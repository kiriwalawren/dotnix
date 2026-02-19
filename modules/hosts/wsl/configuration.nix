{
  configurations.nixos.wsl.modules.coniguration = {
    networking.hostName = "wsl";
    system.stateVersion = "23.11";
    nixpkgs.hostPlatform = "x86_64-linux";
  };
}
