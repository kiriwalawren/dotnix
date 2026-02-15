{
  description = "NixOS configuration";

  inputs = {
    # Repo configuration dependencies
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS system configuration dependencies
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cachix-deploy-flake = {
      url = "github:cachix/cachix-deploy-flake";
      inputs = {
        disko.follows = "disko";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };

    secrets.url = "git+ssh://git@github.com/kiriwalawren/secrets.git?ref=main&shallow=1";

    # User configuration dependencies
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # UI deps
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Server Dependencies
    nixflix = {
      url = "github:kiriwalawren/nixflix/subdomains";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      cachix-deploy-flake,
      home-manager,
      treefmt-nix,
      nixpkgs,
      self,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib // home-manager.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      overlays = [
        inputs.firefox-addons.overlays.default
        inputs.hyprland-contrib.overlays.default
      ];

      perSystem =
        f:
        lib.genAttrs systems (
          system:
          f rec {
            inherit system;
            pkgs = import nixpkgs {
              inherit system overlays;
              config.allowUnfree = true;
              config.allowUnfreePredicate = _: true;
            };
            treefmt = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
          }
        );
    in
    {
      inherit lib;

      formatter = perSystem ({ treefmt, ... }: treefmt.config.build.wrapper);

      checks = perSystem (
        { treefmt, ... }:
        {
          formatting = treefmt.config.build.check self;
        }
      );

      nixosModules = import ./modules/nixos;
      homeManagerModules.dotnix = import ./modules/home;

      nixosConfigurations = import ./hosts (inputs // { inherit overlays; });

      packages = perSystem (
        { pkgs, ... }:
        let
          cachix-deploy-lib = cachix-deploy-flake.lib pkgs;
        in
        {
          cachix-deploy-spec = cachix-deploy-lib.spec {
            agents = {
              home-server = self.nixosConfigurations.home-server.config.system.build.toplevel;
            };
          };
        }
      );

      devShells = perSystem (
        {
          pkgs,
          treefmt,
          ...
        }:
        {
          default = pkgs.mkShell {
            nativeBuildInputs =
              with pkgs;
              [ treefmt.config.build.wrapper ]
              ++ (lib.attrValues treefmt.config.build.programs)
              ++ [
                age
                cachix
                sops
                ssh-to-age
                yq-go
              ];
          };
        }
      );
    };
}
