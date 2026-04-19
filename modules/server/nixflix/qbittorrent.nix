{
  flake.modules.nixos.homelab =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      qbCfg = config.nixflix.torrentClients.qbittorrent;
    in
    {
      sops.secrets = {
        "qbittorrent/password" = { };
      };

      nixflix.torrentClients.qbittorrent = {
        enable = true;
        subdomain = "torrent";
        password._secret = config.sops.secrets."qbittorrent/password".path;
        serverConfig = {
          LegalNotice.Accepted = true;
          BitTorrent = {
            Session = {
              AddTorrentStopped = false;
              Port = 45500;
              QueueingSystemEnabled = true;
              SSL.Port = 32380;

              # required for port forwarding from a VPN
              ReannounceWhenAddressChanged = true;
            };
          };
          Preferences = {
            WebUI = {
              Username = "flashback";
              Password_PBKDF2 = "@ByteArray(Mm6dLsEmFAkQ4/VA9S+aKw==:9afs9p8by8P6MJtLzj4kWO/OnK6Kd4Hnw76kqrcOMwDaa+Y24lTOUGM0U2TEkP1Q6kBOCacr5cO0cSPtsSHLXQ==)";
            };
            General.Locale = "en";
          };
        };
      };

      systemd.services.protonvpn-port-forward = lib.mkIf (config.nixflix.vpn.enable && qbCfg.vpn.enable) {
        description = "ProtonVPN port forwarding for qBittorrent";
        after = [
          "${config.systemd.services.qbittorrent.vpnConfinement.vpnNamespace}.service"
          "qbittorrent.service"
        ];
        requires = [
          "${config.systemd.services.qbittorrent.vpnConfinement.vpnNamespace}.service"
          "qbittorrent.service"
        ];
        wantedBy = [ "multi-user.target" ];

        path = [
          pkgs.curl
          pkgs.jq
          pkgs.libnatpmp
          pkgs.iproute2
          pkgs.gawk
        ];

        serviceConfig = {
          Type = "simple";
          Restart = "on-failure";
          RestartSec = "5s";
          ExecStart =
            let
              ns = config.systemd.services.qbittorrent.vpnConfinement.vpnNamespace;
              qbHost = "http://${qbCfg.serverConfig.Preferences.WebUI.Address}:${toString config.services.qbittorrent.webuiPort}";
              qbUser = qbCfg.serverConfig.Preferences.WebUI.Username;
              qbPassFile = config.sops.secrets."qbittorrent/password".path;
            in
            pkgs.writeShellScript "protonvpn-port-forward" ''
              QB_HOST="${qbHost}"
              QB_USER="${qbUser}"
              QB_PASS=$(cat ${qbPassFile})

              QB_COOKIE=$(curl -s -c - --data "username=$QB_USER&password=$QB_PASS" \
                "$QB_HOST/api/v2/auth/login" | grep SID | awk '{print $NF}')

              CURRENT_PORT=$(curl -s -b "SID=$QB_COOKIE" \
                "$QB_HOST/api/v2/app/preferences" | jq '.listen_port')

              while true; do
                UDP_OUT=$(ip netns exec ${ns} natpmpc -a 1 0 udp 60 -g 10.2.0.1)
                ip netns exec ${ns} natpmpc -a 1 0 tcp 60 -g 10.2.0.1

                PORT=$(echo "$UDP_OUT" | grep "Mapped public port" | awk '{print $4}')

                if [ -z "$PORT" ]; then
                  echo "Failed to get port, is the tunnel up?"
                  sleep 5
                  continue
                fi

                if [ "$PORT" != "$CURRENT_PORT" ]; then
                  echo "Port changed: $CURRENT_PORT -> $PORT, updating qBittorrent..."
                  curl -s -b "SID=$QB_COOKIE" \
                    --data "json={\"listen_port\":$PORT,\"random_port\":false}" \
                    "$QB_HOST/api/v2/app/setPreferences"
                  curl -s -b "SID=$QB_COOKIE" \
                    --data "hashes=all" \
                    "$QB_HOST/api/v2/torrents/reannounce"
                  CURRENT_PORT=$PORT
                fi

                sleep 45
              done
            '';
        };
      };
    };
}
