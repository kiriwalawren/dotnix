{
  flake.modules.nixos.nixflix =
    { config, ... }:
    {
      sops.secrets = {
        "qbittorrent/password" = { };
      };

      nixflix.torrentClients.qbittorrent = {
        enable = true;
        subdomain = "torrent";
        password = {
          _secret = config.sops.secrets."qbittorrent/password".path;
        };
        serverConfig = {
          LegalNotice.Accepted = true;
          BitTorrent = {
            Session = {
              AddTorrentStopped = false;
              Interface = "wg0-mullvad";
              InterfaceName = "wg0-mullvad";
              Port = 45500;
              QueueingSystemEnabled = true;
              SSL.Port = 32380;
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
    };
}
