{
  config,
  gitRev,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Create short revision for display
  shortRev = lib.strings.substring 0 7 gitRev;
  locale = "en_US.UTF-8";
in
{
  imports = [
    inputs.nixos-wsl.nixosModules.wsl

    ./cachix-agent.nix
    ./cachix.nix
    ./disks
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
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    optimise.automatic = true;
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = locale;

  i18n.extraLocaleSettings = {
    LC_ADDRESS = locale;
    LC_IDENTIFICATION = locale;
    LC_MEASUREMENT = locale;
    LC_MONETARY = locale;
    LC_NAME = locale;
    LC_NUMERIC = locale;
    LC_PAPER = locale;
    LC_TELEPHONE = locale;
    LC_TIME = locale;
  };

  system = {
    # Set build label to include git revision
    nixos.label = lib.mkForce "${config.system.nixos.version}-${shortRev}";
    configurationRevision = gitRev;

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
