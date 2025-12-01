{
  config,
  gitRev,
  inputs,
  lib,
  pkgs,
  ...
}: let
  # Create short revision for display
  shortRev = lib.strings.substring 0 7 gitRev;
in {
  imports = [
    inputs.nixos-wsl.nixosModules.wsl

    ./cachix-agent.nix
    ./cachix.nix
    ./docker.nix
    ./dual-function-keys.nix
    ./encryption
    ./grub.nix
    ./network
    ./nix-helper.nix
    ./openssh.nix
    ./power-profiles.nix
    ./sops.nix
    ./ssh.nix
    ./user
  ];

  environment.systemPackages = with pkgs; [
    curl
    jq
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
    # Set build label to include git revision
    nixos.label = lib.mkForce "${config.system.nixos.version}-${shortRev}";
    configurationRevision = gitRev;

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
