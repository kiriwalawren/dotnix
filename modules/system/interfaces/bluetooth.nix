{
  flake.modules.nixos.bluetooth = { pkgs, ... }: {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # PS5 DualSense Control
    environment.systemPackages = [
      pkgs.dualsensectl
      pkgs.bluetui
    ];
  };
}
