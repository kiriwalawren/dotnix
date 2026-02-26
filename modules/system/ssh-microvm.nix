{ config, inputs, ... }:
let
  sshKeys = config.flake.users.sshKeys;
  sshModule = config.flake.modules.nixos.ssh;
  user = config.user.name;
in
{
  flake.modules.nixos.ssh-microvm =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.microvm.nixosModules.host ];

      systemd.network = {
        enable = true;
        networks."10-microvm-ssh" = {
          matchConfig.Name = "vm-ssh";
          networkConfig = {
            Address = "10.10.0.1/24";
            ConfigureWithoutCarrier = true;
          };
        };
      };

      networking.nftables = {
        enable = true;
        tables."microvm-nat" = {
          family = "inet";
          content = ''
            chain postrouting {
              type nat hook postrouting priority 100; policy accept;
              ip saddr 10.10.0.0/24 oifname != "vm-ssh" masquerade;
            }
          '';
        };
      };

      # Host-side: decrypt ephemeral Tailscale auth key (persists even after host switches to Headscale)
      sops.secrets.tailscale-ephemeral-auth-key = { };

      microvm.vms.ssh-microvm.config = {
        imports = [ sshModule ];

        microvm = {
          hypervisor = "qemu";
          mem = 512;
          vcpu = 1;

          interfaces = [
            {
              type = "tap";
              id = "vm-ssh";
              mac = "02:00:00:00:00:01";
            }
          ];

          shares = [
            {
              tag = "ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
              proto = "virtiofs";
            }
            {
              tag = "host-secrets";
              source = "/run/secrets";
              mountPoint = "/run/host-secrets";
              proto = "virtiofs";
            }
            {
              tag = "user-secrets";
              source = "/run/secrets-for-users";
              mountPoint = "/run/host-user-secrets";
              proto = "virtiofs";
            }
          ];
        };

        networking = {
          hostName = "ssh-microvm";
          useDHCP = false;
          firewall.trustedInterfaces = [ "tailscale0" ];
        };

        systemd.network = {
          enable = true;
          networks."20-lan" = {
            matchConfig.Type = "ether";
            networkConfig = {
              Address = "10.10.0.2/24";
              Gateway = "10.10.0.1";
              DNS = "1.1.1.1";
            };
          };
        };

        # Guest Tailscale: connects to old Tailscale network (not Headscale)
        services.tailscale = {
          enable = true;
          authKeyFile = "/run/host-secrets/tailscale-ephemeral-auth-key";
          openFirewall = true;
          extraUpFlags = [
            "--accept-routes=false"
            "--force-reauth"
          ];
        };

        # Guest user: key-only SSH access
        users.users.${user} = {
          isNormalUser = true;
          group = "users";
          openssh.authorizedKeys.keys = sshKeys;
        };

        # Copy host user's SSH private key into the guest for outbound SSH to host
        system.activationScripts.linkSshKey.text = ''
          mkdir -p /home/${user}/.ssh
          cp /run/host-user-secrets/${user}_ssh_key /home/${user}/.ssh/id_ed25519
          chown ${user}:users /home/${user}/.ssh/id_ed25519
          chmod 0400 /home/${user}/.ssh/id_ed25519
          chown ${user}:users /home/${user}/.ssh
          chmod 0700 /home/${user}/.ssh
        '';

        system.stateVersion = "25.11";
      };
    };
}
