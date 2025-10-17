{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixos-wsl.nixosModules.wsl

    ./cachix.nix
    ./cachix-agent.nix
    ./ddns.nix
    ./docker.nix
    ./dual-function-keys.nix
    ./grub.nix
    ./network.nix
    ./nix-helper.nix
    ./openssh.nix
    ./power-profiles.nix
    ./sops.nix
    ./ssh.nix
    ./tailscale-client.nix
    ./user
  ];

  environment.systemPackages = with pkgs; [
    curl
    wget
  ];

  wsl = {
    defaultUser = config.user.name;
    interop.includePath = false;
  };
  programs.dconf.enable = true; # Configuration System & Setting Management - required for Home Manager

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = _: true;

  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    optimise.automatic = true;
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  system = {
    autoUpgrade = {
      enable = true;
      flake = "github:kiriwalawren/dotnix";
      persistent = true;
    };

    cachix.enable = true; # Binary Cache
    nix-helper.enable = true;
    dual-function-keys = {
      "KEY_CAPSLOCK" = {
        tap = "KEY_ESC";
        hold = "KEY_LEFTCTRL";
      };
    };
  };
}
