{
  flake.modules.nixos.nixflix =
    { config, ... }:
    {
      nixflix.qbittorrent = {
        enable = true;
        subdomain = "torrent";
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
              Username = "admin";
              Password_PBKDF2 = "@ByteArray(jWBXj7ktN13zUMGMmvYkOQ==:GRq7UIBZ5Otb55uD3G3JD7KzraxcU4vVWLqvsQ6mZiIEy2JVLkllbh53pPQqlHPyD0+2ga+kvyGjIddO5NNo1w==)";
            };
            General.Locale = "en";
          };
        };
      };
    };
}
