{
  description = "Minimal NixOS configuration for bootstrapping systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    inherit (self) inputs;

    mkNixosConfiguration = {
      name,
      device ? "/dev/sda",
      efi ? true,
      modules ? [],
      system ? "x86_64-linux",
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;

        modules =
          [
            inputs.nixos-wsl.nixosModules.wsl
            inputs.disko.nixosModules.disko
            (import ../hosts/disko.nix {
              inherit (nixpkgs) lib;
              inherit device;
            })

            ../modules/nixos/system/cachix.nix
            ../modules/nixos/system/network.nix
            ../modules/nixos/system/openssh.nix
            ../modules/nixos/system/ssh.nix
            ../modules/nixos/system/user

            ({
              lib,
              pkgs,
              ...
            }: {
              system = {
                stateVersion = "25.05"; # Update when reinstalling

                cachix.enable = true;
                openssh.enable = true;
              };

              environment.systemPackages = with pkgs; [
                curl
                git
                rsync
                wget
                bashInteractive # always safe to include even if using fish
              ];

              # Allow unfree packages
              nixpkgs.config.allowUnfree = true;
              nixpkgs.config.allowUnfreePredicate = _: true;

              nix.settings.experimental-features = ["nix-command" "flakes"];

              services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
              users.users.root = {
                openssh.authorizedKeys.keys = lib.lists.forEach (lib.filesystem.listFilesRecursive ../modules/nixos/system/user/keys) (key: builtins.readFile key);
              };

              isMinimal = true;
            })
          ]
          ++ modules;

        specialArgs = {
          inherit inputs system name;
        };
      };

    mkNixosConfigurations = nixpkgs.lib.foldl (
      acc: conf:
        {
          "${conf.name}" = mkNixosConfiguration conf;
        }
        // acc
    ) {};
  in {
    nixosConfigurations = mkNixosConfigurations [
      {
        name = "nixos-mediaserver";
        device = "/dev/nvme0n1";
        modules = [
          ../hosts/hardware/nixos-mediaserver.nix
          {
            user.name = "kiri";

            boot.loader = {
              grub = {
                enable = true;
                device = "nodev";
                efiSupport = true;
              };

              efi = {
                canTouchEfiVariables = true;
                efiSysMountPoint = "/boot/efi";
              };
            };
          }
        ];
      }

      {
        name = "nixos-framework13";
        device = "/dev/nvme0n1";
        modules = [
          ../hosts/hardware/nixos-framework13.nix

          {
            user.name = "walawren";

            boot.loader = {
              grub = {
                enable = true;
                device = "nodev";
                efiSupport = true;
                efiInstallAsRemovable = false;
              };

              efi = {
                canTouchEfiVariables = true;
                efiSysMountPoint = "/boot/efi";
              };
            };

            services.fwupd.enable = true;
          }
        ];
      }
    ];
  };
}
